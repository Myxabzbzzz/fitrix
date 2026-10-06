import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/data/repositories/chat_repository.dart';
import 'package:fitrix/features/chat/data/services/chat_api_service.dart';
import 'package:fitrix/features/chat/presentation/providers/chat_provider.dart';

/// Local stand-in for the Node backend's /chat/stream endpoint.
class FakeBackend {
  late final HttpServer _server;

  /// Decides the response for each request.
  Future<void> Function(HttpResponse response) handler = (response) async {};

  int requests = 0;

  String get baseUrl => 'http://${_server.address.host}:${_server.port}';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((request) async {
      requests++;
      await utf8.decoder.bind(request).join();
      await handler(request.response);
      await request.response.close();
    });
  }

  Future<void> stop() => _server.close(force: true);

  static Future<void> Function(HttpResponse) streaming(
    List<String> deltas, {
    bool done = true,
  }) {
    return (response) async {
      response.headers.contentType =
          ContentType('application', 'x-ndjson', charset: 'utf-8');
      for (final delta in deltas) {
        response.write('${jsonEncode({'delta': delta})}\n');
        await response.flush();
      }
      if (done) response.write('${jsonEncode({'done': true})}\n');
    };
  }

  static Future<void> Function(HttpResponse) error(int status, String message) {
    return (response) async {
      response.statusCode = status;
      response.headers.contentType = ContentType.json;
      response.write(jsonEncode({'error': 'x', 'message': message}));
    };
  }
}

void main() {
  late FakeBackend backend;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    backend = FakeBackend();
    await backend.start();
  });

  tearDown(() => backend.stop());

  group('ChatApiService.streamMessage', () {
    test('yields deltas as they arrive', () async {
      backend.handler = FakeBackend.streaming(['Hey', ' there', '!']);
      final api = ChatApiService(baseUrl: backend.baseUrl);

      final chunks = await api.streamMessage('hi', 'c1').toList();

      expect(chunks, ['Hey', ' there', '!']);
    });

    test('surfaces the backend error message', () async {
      backend.handler = FakeBackend.error(502, 'Ollama has no model "x"');
      final api = ChatApiService(baseUrl: backend.baseUrl);

      expect(
        api.streamMessage('hi', 'c1').toList(),
        throwsA(isA<ChatException>().having(
          (e) => e.message,
          'message',
          'Ollama has no model "x"',
        )),
      );
    });

    test('fails if the stream ends without "done"', () async {
      backend.handler = FakeBackend.streaming(['partial'], done: false);
      final api = ChatApiService(baseUrl: backend.baseUrl);

      expect(
        api.streamMessage('hi', 'c1').toList(),
        throwsA(isA<ChatException>()),
      );
    });

    test('falls back to an offline reply when the backend is down', () async {
      final port = backend._server.port;
      await backend.stop();
      final api = ChatApiService(baseUrl: 'http://127.0.0.1:$port');

      final chunks = await api.streamMessage('Build muscle', 'c1').toList();

      expect(chunks.join(), contains('Nice choice'));
    });
  });

  group('ChatNotifier', () {
    ChatNotifier notifierFor(FakeBackend backend) => ChatNotifier(
          ChatRepository(
            ChatApiService(baseUrl: backend.baseUrl),
            greeting: const ['Hi, I am Felix'],
          ),
        );

    Future<List<ChatMessage>> loaded(ChatNotifier notifier) async {
      while (notifier.state.valueOrNull == null) {
        await Future<void>.delayed(Duration.zero);
      }
      return notifier.state.requireValue;
    }

    test('streams the reply into one assistant message and saves it', () async {
      backend.handler = FakeBackend.streaming(['Squats', ' and', ' rows.']);
      final notifier = notifierFor(backend);
      await loaded(notifier);

      await notifier.sendMessage('What should I train?');

      final messages = notifier.state.requireValue;
      expect(messages.map((m) => m.content), [
        'Hi, I am Felix',
        'What should I train?',
        'Squats and rows.',
      ]);
      expect(messages.last.isStreaming, isFalse);
      expect(notifier.isReplying, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('chat_history'), contains('Squats and rows.'));
    });

    test('keeps the chat on failure and retries the same message', () async {
      backend.handler = FakeBackend.error(503, 'Ollama is not running');
      final notifier = notifierFor(backend);
      await loaded(notifier);

      await notifier.sendMessage('Plan my week');

      var messages = notifier.state.requireValue;
      expect(messages, hasLength(3), reason: 'history must not be wiped');
      expect(messages.last.isFailed, isTrue);
      expect(messages.last.content, 'Ollama is not running');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('chat_history'), isNot(contains('not running')));

      backend.handler = FakeBackend.streaming(['Mon: legs']);
      await notifier.retry();

      messages = notifier.state.requireValue;
      expect(messages.map((m) => m.content), [
        'Hi, I am Felix',
        'Plan my week',
        'Mon: legs',
      ]);
      expect(messages.any((m) => m.isFailed), isFalse);
    });

    test('ignores sends while a reply is streaming', () async {
      final release = Completer<void>();
      backend.handler = (response) async {
        response.write('${jsonEncode({'delta': 'Working on it'})}\n');
        await response.flush();
        await release.future;
        response.write('${jsonEncode({'done': true})}\n');
      };
      final notifier = notifierFor(backend);
      await loaded(notifier);

      final first = notifier.sendMessage('one');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await notifier.sendMessage('two');
      release.complete();
      await first;

      expect(backend.requests, 1);
      expect(
        notifier.state.requireValue.map((m) => m.content),
        ['Hi, I am Felix', 'one', 'Working on it'],
      );
    });
  });
}
