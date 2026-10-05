import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/data/services/chat_api_service.dart';

class ChatRepository {
  final ChatApiService _apiService;
  final Uuid _uuid = const Uuid();

  /// SharedPreferences keys, so each Felix chat keeps its own history and
  /// backend conversation. Defaults are the onboarding / app assistant chat.
  final String historyKey;
  final String conversationKey;

  /// Messages shown when the chat has no history yet.
  final List<String> greeting;

  ChatRepository(
    this._apiService, {
    this.historyKey = AppConstants.keyChatHistory,
    this.conversationKey = AppConstants.keyConversationId,
    this.greeting = const [
      AppConstants.assistantGreeting,
      AppConstants.assistantIntro,
      AppConstants.assistantQuestion,
    ],
  });

  Future<List<ChatMessage>> getMessages() async {
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = ChatMessage.encodeMessages(messages);
    await prefs.setString(historyKey, messagesJson);
  }

  Future<String> getOrCreateConversationId() async {
    final prefs = await SharedPreferences.getInstance();
    String? conversationId = prefs.getString(conversationKey);

    if (conversationId == null) {
      conversationId = _uuid.v4();
      await prefs.setString(conversationKey, conversationId);
    }

    return conversationId;
  }

  Future<String> sendMessage(String message) async {
    final conversationId = await getOrCreateConversationId();
    return await _apiService.sendMessage(message, conversationId);
  }

  List<ChatMessage> _getInitialMessages() {
    final now = DateTime.now();
    return [
      for (var i = 0; i < greeting.length; i++)
        ChatMessage(
          id: _uuid.v4(),
          content: greeting[i],
          sender: MessageSender.assistant,
          timestamp: now.add(Duration(seconds: i)),
        ),
    ];
  }
}
