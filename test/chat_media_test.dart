import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/features/language/presentation/providers/language_provider.dart';
import 'package:fitrix/features/chat/data/models/chat_action.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/data/repositories/chat_repository.dart';
import 'package:fitrix/features/chat/data/services/chat_api_service.dart';
import 'package:fitrix/features/chat/data/services/photo_service.dart';
import 'package:image/image.dart' as img;
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
    final name = 'p${_n++}.jpg';
    File('${dir.path}/chat_photos/$name')
        .writeAsBytesSync(List.filled(bytes, 7));
    return 'chat_photos/$name';
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
    void Function(ChatAction action)? onAction,
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
    Map<String, Object>? context,
    List<String>? images,
    void Function(ChatAction action)? onAction,
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
    Directory('${tmp.path}/chat_photos').createSync();
    documentsDirLoader = () async => tmp.path;
    resetChatDocsDir();
    photos = FakePhotos(tmp);
  });

  tearDown(() {
    resetChatDocsDir();
    tmp.deleteSync(recursive: true);
  });

  List<FileSystemEntity> stored() =>
      Directory('${tmp.path}/chat_photos').listSync();

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

    testWidgets('a late result after stop does not change the field',
        (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('chat-mic')));
      await tester.pump();
      speech.say('hello');
      await tester.tap(find.byKey(const ValueKey('chat-mic')));
      await tester.pump();
      speech.say('hello world');
      await tester.pump();
      expect(fieldText(tester), 'hello');
    });

    testWidgets('sending stops dictation; a late result does not refill',
        (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('chat-mic')));
      await tester.pump();
      speech.say('hello');
      await tester.tap(find.byIcon(Icons.arrow_circle_up));
      await tester.pump();
      speech.say('hello again');
      await tester.pump();
      expect(repo.sent.single, 'hello');
      expect(fieldText(tester), isEmpty);
      expect(speech.stopCalls, 1);
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
      expect(stored(), isEmpty, reason: 'removed photo is deleted');
    });

    testWidgets('the remove button works near the edge of its hit area',
        (tester) async {
      await pump(tester);
      await choose(tester);
      final rect =
          tester.getRect(find.byKey(const ValueKey('chat-remove-photo')));
      final box =
          tester.getRect(find.byKey(const ValueKey('chat-pending-photo')));
      expect(rect.width, greaterThanOrEqualTo(44));
      expect(box.contains(rect.topRight - const Offset(1, -1)), isTrue);
      await tester.tapAt(rect.topRight + const Offset(-3, 3));
      await tester.pump();
      expect(find.byKey(const ValueKey('chat-pending-photo')), findsNothing);
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
      expect(repo.imagePaths.single, startsWith('chat_photos/'));
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
      expect(stored(), isEmpty);
    });
  });

  group('normalizeChatPhoto', () {
    bool isJpeg(List<int> b) => b[0] == 0xFF && b[1] == 0xD8;

    test('a PNG becomes a JPEG', () async {
      final png =
          Uint8List.fromList(img.encodePng(img.Image(width: 64, height: 32)));
      final out = await normalizeChatPhoto(png);
      expect(isJpeg(out!), isTrue);
    });

    test('a small JPEG is kept as is', () async {
      final jpg =
          Uint8List.fromList(img.encodeJpg(img.Image(width: 64, height: 32)));
      expect(identical(await normalizeChatPhoto(jpg), jpg), isTrue);
    });

    test('an oversize photo is recompressed to <= 1280 px and the limit',
        () async {
      final noisy = img.Image(width: 2400, height: 1800);
      var v = 12345;
      for (final px in noisy) {
        v = (v * 1103515245 + 12345) & 0x7fffffff;
        px.setRgb(v & 255, (v >> 8) & 255, (v >> 16) & 255);
      }
      final big = Uint8List.fromList(img.encodeJpg(noisy, quality: 100));
      expect(big.length, greaterThan(maxChatPhotoBytes));

      final out = await normalizeChatPhoto(big);
      expect(out, isNotNull);
      expect(out!.length, lessThanOrEqualTo(maxChatPhotoBytes));
      final decoded = img.decodeJpg(out)!;
      expect(decoded.width, 1280);
      expect(decoded.height, 960);
    });

    test('an EXIF-rotated photo comes out upright', () async {
      final noisy = img.Image(width: 2400, height: 1800);
      var v = 54321;
      for (final px in noisy) {
        v = (v * 1103515245 + 12345) & 0x7fffffff;
        px.setRgb(v & 255, (v >> 8) & 255, (v >> 16) & 255);
      }
      noisy.exif.imageIfd.orientation = 6; // rotate 90° clockwise
      final big = Uint8List.fromList(img.encodeJpg(noisy, quality: 100));
      expect(big.length, greaterThan(maxChatPhotoBytes));

      final decoded = img.decodeJpg((await normalizeChatPhoto(big))!)!;
      expect(decoded.width, 960);
      expect(decoded.height, 1280);
    });
  });

  test('resolveChatPhoto handles relative and old-container paths', () {
    expect(resolveChatPhoto('/new', 'chat_photos/a.jpg'),
        '/new/chat_photos/a.jpg');
    expect(resolveChatPhoto('/new', '/old/Documents/chat_photos/a.jpg'),
        '/new/chat_photos/a.jpg');
  });

  group('request', () {
    test('repository sends the photo as base64 images, only on that turn',
        () async {
      SharedPreferences.setMockInitialValues({});
      final api = ImageApi();
      final repository = ChatRepository(api);
      final file = File('${tmp.path}/chat_photos/a.jpg')
        ..writeAsBytesSync([1, 2, 3, 4]);

      await repository
          .streamMessage('look', imagePath: 'chat_photos/a.jpg')
          .toList();
      // A path from an old app container resolves by file name.
      await repository
          .streamMessage('again',
              imagePath: '/old/Containers/ABC/Documents/chat_photos/a.jpg')
          .toList();
      expect(file.existsSync(), isTrue);
      await repository.streamMessage('and now?').toList();

      expect(api.images[0], [
        base64Encode([1, 2, 3, 4])
      ]);
      expect(api.images[1], [
        base64Encode([1, 2, 3, 4])
      ]);
      expect(api.images[2], isEmpty);
    });

    test('an oversize or missing photo is not sent', () async {
      final repository = ChatRepository(ImageApi());
      File('${tmp.path}/chat_photos/big.jpg')
          .writeAsBytesSync(List.filled(maxChatPhotoBytes + 1, 1));
      expect(
          repository
              .streamMessage('x', imagePath: 'chat_photos/big.jpg')
              .toList(),
          throwsA(isA<ChatException>()));
      expect(
          repository
              .streamMessage('x', imagePath: 'chat_photos/nope.jpg')
              .toList(),
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
