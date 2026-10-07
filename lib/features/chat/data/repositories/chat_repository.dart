import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/data/services/chat_api_service.dart';
import 'package:fitrix/features/profile/data/models/user_profile.dart';
import 'package:fitrix/features/profile/data/repositories/profile_repository.dart';

class ChatRepository {
  final ChatApiService _apiService;
  final ProfileRepository? _profileRepository;
  final Uuid _uuid = const Uuid();

  /// SharedPreferences keys, so each Felix chat keeps its own history and
  /// backend conversation. Defaults are the onboarding / app assistant chat.
  final String historyKey;
  final String conversationKey;

  /// Backend persona for this chat, see [AssistantTopic.apiTopic].
  final String topic;

  /// Messages shown when the chat has no history yet.
  final List<String> greeting;

  /// The app's current language code, sent so Felix answers in it.
  final String Function()? _language;

  ChatRepository(
    this._apiService, {
    ProfileRepository? profileRepository,
    this.historyKey = AppConstants.keyChatHistory,
    this.conversationKey = AppConstants.keyConversationId,
    this.topic = AssistantTopic.appApiTopic,
    this.greeting = const [
      AppConstants.assistantGreeting,
      AppConstants.assistantIntro,
      AppConstants.assistantQuestion,
    ],
    SharedPreferences? prefs,
    void Function()? onSaved,
    String Function()? language,
  })  : _profileRepository = profileRepository,
        _language = language,
        _preloadedPrefs = prefs,
        _onSaved = onSaved;

  /// The app's preloaded storage; falls back to the shared instance.
  final SharedPreferences? _preloadedPrefs;

  /// Called after the history was saved (used to trigger sync).
  final void Function()? _onSaved;

  Future<SharedPreferences> _prefs() async =>
      _preloadedPrefs ?? await SharedPreferences.getInstance();

  Future<List<ChatMessage>> getMessages() async {
    final prefs = await _prefs();
    final messagesJson = prefs.getString(historyKey);

    if (messagesJson == null || messagesJson.isEmpty) {
      return _getInitialMessages();
    }

    try {
      return ChatMessage.decodeMessages(messagesJson);
    } catch (e) {
      return _getInitialMessages();
    }
  }

  Future<void> saveMessages(List<ChatMessage> messages) async {
    final prefs = await _prefs();
    final messagesJson = ChatMessage.encodeMessages(messages);
    await prefs.setString(historyKey, messagesJson);
    _onSaved?.call();
  }

  Future<String> getOrCreateConversationId() async {
    final prefs = await _prefs();
    String? conversationId = prefs.getString(conversationKey);

    if (conversationId == null) {
      conversationId = _uuid.v4();
      await prefs.setString(conversationKey, conversationId);
    }

    return conversationId;
  }

  /// Streams Felix's reply to [message] chunk by chunk.
  ///
  /// [context] is the chat as shown before [message] (without it); its
  /// recent completed turns are sent along with this chat's topic and the
  /// user's profile, so Felix keeps context even if the backend restarted.
  Stream<String> streamMessage(
    String message, {
    List<ChatMessage> context = const [],
  }) async* {
    final conversationId = await getOrCreateConversationId();
    yield* _apiService.streamMessage(
      message,
      conversationId,
      topic: topic,
      profile: await _loadProfile(),
      history: ChatMessage.toApiHistory(context),
      language: _language?.call(),
    );
  }

  Future<Map<String, Object>> _loadProfile() async {
    final repository = _profileRepository;
    if (repository == null) return const {};
    try {
      return profilePayload(await repository.getProfile());
    } catch (e) {
      // Felix can still answer without the profile.
      debugPrint('Could not load profile for Felix: $e');
      return const {};
    }
  }

  /// The profile as the backend expects it: `name`, `age`, `weightKg`,
  /// `heightCm`, each left out when empty or not a number.
  static Map<String, Object> profilePayload(UserProfile? profile) {
    if (profile == null) return const {};
    final name = profile.name.trim();
    final age = _number(profile.age);
    final weight = _number(profile.weight);
    final height = _number(profile.height);
    return {
      if (name.isNotEmpty) 'name': name,
      if (age != null) 'age': age.round(),
      if (weight != null) 'weightKg': weight,
      if (height != null) 'heightCm': height,
    };
  }

  /// First number in [text] ("82", "82.5 kg", "82,5"), or null.
  static num? _number(String text) {
    final match = RegExp(r'\d+(?:[.,]\d+)?').firstMatch(text);
    if (match == null) return null;
    final value = double.tryParse(match.group(0)!.replaceAll(',', '.'));
    if (value == null || value <= 0) return null;
    return value == value.roundToDouble() ? value.round() : value;
  }

  List<ChatMessage> _getInitialMessages() {
    final now = DateTime.now();
    return [
      // In order and all in the past, so a reply sent right away sorts
      // after them when chats from several devices are merged.
      for (var i = 0; i < greeting.length; i++)
        ChatMessage(
          id: _uuid.v4(),
          content: greeting[i],
          sender: MessageSender.assistant,
          timestamp: now.subtract(Duration(milliseconds: greeting.length - i)),
        ),
    ];
  }
}
