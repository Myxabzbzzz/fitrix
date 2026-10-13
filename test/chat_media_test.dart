import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/features/language/presentation/providers/language_provider.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/data/repositories/chat_repository.dart';
import 'package:fitrix/features/chat/data/services/chat_api_service.dart';
import 'package:fitrix/features/chat/data/services/photo_service.dart';
import 'package:fitrix/features/chat/data/services/speech_service.dart';
import 'package:fitrix/features/chat/presentation/providers/chat_provider.dart';
import 'package:fitrix/features/chat/presentation/screens/felix_chat_screen.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

class FakeSpeech implements SpeechService {
  bool allowed = true;
  int initCalls = 0;
  int stopCalls = 0;
  String? localeUsed;
  void Function(String text)? _onResult;
  VoidCallback? _onStopped;
  List<String> available = ['en_US', 'ru-RU', 'es_ES'];

  @override
  Future<bool> initialize() async {
    initCalls++;
    return allowed;
  }

  @override
  Future<List<String>> locales() async => available;

  @override
  Future<void> listen({
    required String? localeId,
    required void Function(String text) onResult,
    required VoidCallback onStopped,
  }) async {
    localeUsed = localeId;
    _onResult = onResult;
    _onStopped = onStopped;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    _onStopped?.call();
  }

  void say(String words) => _onResult!(words);
  void silence() => _onStopped!();
}

class FakePhotos implements PhotoService {
  FakePhotos(this.dir);
  final Directory dir;
  int bytes = 2000;
  PhotoSource? lastSource;
  int _n = 0;

  @override
  Future<String?> pick(PhotoSource source) async {
    lastSource = source;
    final file = File('${dir.path}/p${_n++}.jpg')
      ..writeAsBytesSync(List.filled(bytes, 7));
    return file.path;
  }
}

class RecordingRepo extends ChatRepository {
  RecordingRepo(super.api, {super.prefs});
  final imagePaths = <String?>[];
  final sent = <String>[];

  @override
  Stream<String> streamMessage(
    String message, {
    List<ChatMessage> context = const [],
    String? imagePath,
  }) async* {
    sent.add(message);
    imagePaths.add(imagePath);
    yield 'Nice';
  }
}

class ImageApi extends ChatApiService {
  final images = <List<String>?>[];

  @override
  Stream<String> streamMessage(
    String message,
    String conversationId, {
    String? topic,
    Map<String, Object>? profile,
    List<Map<String, String>>? history,
    String? language,
    List<String>? images,
  }) async* {
    this.images.add(images);
    yield 'ok';
  }
}

void main() {
  late Directory tmp;
  late FakeSpeech speech;
  late FakePhotos photos;
  late RecordingRepo repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tmp = Directory.systemTemp.createTempSync('fc_media');
    speech = FakeSpeech();
    photos = FakePhotos(tmp);
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  Future<void> pump(WidgetTester tester,
      {String language = 'en', bool reduced = false}) async {
    tester.view.physicalSize = const Size(375, 667) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(
        {AppConstants.keyLanguage: language});
    final prefs = await SharedPreferences.getInstance();
    repo = RecordingRepo(ImageApi(), prefs: prefs);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        speechServiceProvider.overrideWithValue(speech),
        photoServiceProvider.overrideWithValue(photos),
        selectedLanguageProvider.overrideWith((ref) => LanguageNotifier(prefs)),
        chatMessagesProvider.overrideWith((ref) => ChatNotifier(repo)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale(language),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: child!,
        ),
        home: const FelixChatScreen(),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
  }

  final field = find.byType(TextField);
  String fieldText(WidgetTester t) =>
      t.widget<TextField>(field).controller!.text;

  group('speechLocaleFor', () {
    const device = ['en_US', 'ru_RU', 'es_ES'];
    test('maps app languages to dictation locales', () {
      expect(speechLocaleFor('en', device), 'en_US');
      expect(speechLocaleFor('ru', device), 'ru_RU');
      expect(speechLocaleFor('es', device), 'es_ES');
      expect(speechLocaleFor('en', ['en-US']), 'en-US');
    });
    test('uz uses uz-UZ when listed, else ru-RU', () {
      expect(speechLocaleFor('uz', [...device, 'uz_UZ']), 'uz_UZ');
      expect(speechLocaleFor('uz', device), 'ru_RU');
    });
    test('null when the device lacks the locale', () {
      expect(speechLocaleFor('es', ['en_US']), isNull);
    });
  });

  group('dictation', () {
    testWidgets('partial results fill the field; tap again stops',
        (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('chat-mic')));
      await tester.pump();
      expect(speech.localeUsed, 'en_US');

      speech.say('hello');
      speech.say('hello felix');
      await tester.pump();
      expect(fieldText(tester), 'hello felix');

      await tester.tap(find.byKey(const ValueKey('chat-mic')));
      await tester.pump();
      expect(speech.stopCalls, 1);
      expect(fieldText(tester), 'hello felix');
      expect(find.byIcon(Icons.mic), findsNothing);
    });

    testWidgets('appends to typed text and stops on silence', (tester) async {
      await pump(tester);
      await tester.enterText(field, 'Hi');
      await tester.tap(find.byKey(const ValueKey('chat-mic')));
      await tester.pump();
      expect(find.byIcon(Icons.mic), findsOneWidget);
      speech.say('there');
      speech.silence();
      await tester.pump();
      expect(fieldText(tester), 'Hi there');
      expect(find.byIcon(Icons.mic), findsNothing);
    });

    testWidgets('uses the Russian locale for the Russian app', (tester) async {
      await pump(tester, language: 'ru');
      await tester.tap(find.byKey(const ValueKey('chat-mic')));
      await tester.pump();
      expect(speech.localeUsed, 'ru-RU');
    });

    testWidgets('denied permission shows the settings hint', (tester) async {
      speech.allowed = false;
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('chat-mic')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Open Settings'), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsNothing);
    });

    testWidgets('with reduced motion the listening state does not animate',
        (tester) async {
      await pump(tester, reduced: true);
      await tester.tap(find.byKey(const ValueKey('chat-mic')));
      await tester.pump();
      expect(find.byIcon(Icons.mic), findsOneWidget);
      await tester.pumpAndSettle(); // would time out if a pulse repeated
    });
  });

  group('photos', () {
    Future<void> choose(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('chat-add')));
      await tester.pumpAndSettle();
      expect(find.text('Take photo'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('photo-source-library')));
      await tester.pumpAndSettle();
    }

    testWidgets('picked photo shows as a removable thumbnail', (tester) async {
      await pump(tester);
      await choose(tester);
      expect(photos.lastSource, PhotoSource.library);
      expect(find.byKey(const ValueKey('chat-pending-photo')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('chat-remove-photo')));
      await tester.pump();
      expect(find.byKey(const ValueKey('chat-pending-photo')), findsNothing);
      expect(tmp.listSync(), isEmpty, reason: 'removed photo is deleted');
    });

    testWidgets('sending passes the photo and shows it in the bubble',
        (tester) async {
      await pump(tester);
      await choose(tester);
      await tester.enterText(field, 'What is this?');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));

      expect(repo.sent.single, 'What is this?');
      expect(repo.imagePaths.single, startsWith(tmp.path));
      expect(find.byKey(const ValueKey('chat-pending-photo')), findsNothing);
      expect(find.byKey(const ValueKey('chat-bubble-image')), findsOneWidget);

      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('chat-bubble-image')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('chat-photo-viewer')), findsOneWidget);
    });

    testWidgets('a photo alone sends with a default question', (tester) async {
      await pump(tester);
      await choose(tester);
      await tester.tap(find.byIcon(Icons.arrow_circle_up));
      await tester.pump(const Duration(milliseconds: 100));
      expect(repo.sent.single, 'What do you think of this photo?');
      expect(repo.imagePaths.single, isNotNull);
    });

    testWidgets('an oversize photo is rejected with a message', (tester) async {
      photos.bytes = maxChatPhotoBytes + 1;
      await pump(tester);
      await choose(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('chat-pending-photo')), findsNothing);
      expect(find.textContaining('too large'), findsOneWidget);
      expect(tmp.listSync(), isEmpty);
    });
  });

  group('request', () {
    test('repository sends the photo as base64 images, only on that turn',
        () async {
      SharedPreferences.setMockInitialValues({});
      final api = ImageApi();
      final repository = ChatRepository(api);
      final file = File('${tmp.path}/a.jpg')..writeAsBytesSync([1, 2, 3, 4]);

      await repository.streamMessage('look', imagePath: file.path).toList();
      await repository.streamMessage('and now?').toList();

      expect(api.images[0], [
        base64Encode([1, 2, 3, 4])
      ]);
      expect(api.images[1], isEmpty);
    });

    test('an oversize or missing photo is not sent', () async {
      final repository = ChatRepository(ImageApi());
      final big = File('${tmp.path}/big.jpg')
        ..writeAsBytesSync(List.filled(maxChatPhotoBytes + 1, 1));
      expect(repository.streamMessage('x', imagePath: big.path).toList(),
          throwsA(isA<ChatException>()));
      expect(
          repository.streamMessage('x', imagePath: '${tmp.path}/nope').toList(),
          throwsA(isA<ChatException>()));
    });

    test('imagePath is stored locally but never part of the API history', () {
      final m = ChatMessage(
        id: '1',
        content: 'look',
        sender: MessageSender.user,
        timestamp: DateTime(2026),
        imagePath: '/x/a.jpg',
      );
      final round = ChatMessage.decodeMessages(ChatMessage.encodeMessages([m]));
      expect(round.single.imagePath, '/x/a.jpg');
      expect(ChatMessage.toApiHistory([m]).single.keys, ['role', 'content']);
    });
  });
}
