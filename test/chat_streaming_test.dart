import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/data/repositories/chat_repository.dart';
import 'package:fitrix/features/chat/data/services/chat_api_service.dart';
import 'package:fitrix/features/chat/presentation/providers/chat_provider.dart';
import 'package:fitrix/features/profile/data/models/user_profile.dart';
import 'package:fitrix/features/profile/data/repositories/profile_repository.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';

/// Local stand-in for the Node backend's /chat/stream endpoint.
class FakeBackend {
  late final HttpServer _server;

  /// Decides the response for each request.
  Future<void> Function(HttpResponse response) handler = (response) async {};

  int requests = 0;

  /// JSON bodies of the requests received, in order.
  final bodies = <Map<String, dynamic>>[];

  /// `Authorization` header of each request (null when absent), in order.
  final authorizations = <String?>[];

  String get baseUrl => 'http://${_server.address.host}:${_server.port}';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((request) async {
      requests++;
      authorizations
          .add(request.headers.value(HttpHeaders.authorizationHeader));
      final body = await utf8.decoder.bind(request).join();
      bodies.add(jsonDecode(body) as Map<String, dynamic>);
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

    test('a backend error fails as unavailable, keeping its text for logs',
        () async {
      backend.handler = FakeBackend.error(502, 'Ollama has no model "x"');
      final api = ChatApiService(baseUrl: backend.baseUrl);

      expect(
        api.streamMessage('hi', 'c1').toList(),
        throwsA(isA<ChatException>()
            .having((e) => e.failure, 'failure', ChatFailure.unavailable)
            .having((e) => e.detail, 'detail', 'Ollama has no model "x"')),
      );
    });

    test('fails if the stream ends without "done"', () async {
      backend.handler = FakeBackend.streaming(['partial'], done: false);
      final api = ChatApiService(baseUrl: backend.baseUrl);

      expect(
        api.streamMessage('hi', 'c1').toList(),
        throwsA(isA<ChatException>()
            .having((e) => e.failure, 'failure', ChatFailure.interrupted)),
      );
    });

    test('an unreachable backend fails; nothing is made up', () async {
      final port = backend._server.port;
      await backend.stop();
      final api = ChatApiService(baseUrl: 'http://127.0.0.1:$port');

      expect(
        api.streamMessage('Build muscle', 'c1').toList(),
        throwsA(isA<ChatException>()
            .having((e) => e.failure, 'failure', ChatFailure.unavailable)),
      );
    });

    test('an unreadable stream line fails as unreadable', () async {
      backend.handler = (response) async => response.write('not json\n');
      final api = ChatApiService(baseUrl: backend.baseUrl);

      expect(
        api.streamMessage('hi', 'c1').toList(),
        throwsA(isA<ChatException>()
            .having((e) => e.failure, 'failure', ChatFailure.unreadable)),
      );
    });
  });

  group('ChatNotifier', () {
    ChatNotifier notifierFor(FakeBackend backend) => ChatNotifier(
          ChatRepository(
            ChatApiService(baseUrl: backend.baseUrl),
            greeting: () => const ['Hi, I am Felix'],
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
      expect(messages.map((m) => m.content), ['Hi, I am Felix', 'Plan my week'],
          reason: 'no reply bubble, and history is not wiped');
      expect(messages.last.sender, MessageSender.user);
      expect(messages.last.failure, ChatFailure.unavailable);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('chat_history'), isNot(contains('not running')));
      expect(prefs.getString('chat_history'), contains('Plan my week'),
          reason: 'the question itself is kept');

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

    test('backend down: the question fails, nothing fake is stored', () async {
      final port = backend._server.port;
      await backend.stop();
      final notifier = ChatNotifier(
        ChatRepository(
          ChatApiService(baseUrl: 'http://127.0.0.1:$port'),
          greeting: () => const ['Hi, I am Felix'],
        ),
      );
      await loaded(notifier);

      await notifier.sendMessage('Привет, ты тут?');

      final messages = notifier.state.requireValue;
      expect(messages.map((m) => m.content),
          ['Hi, I am Felix', 'Привет, ты тут?']);
      expect(messages.last.failure, ChatFailure.unavailable);
      final stored = ChatMessage.decodeMessages(
          (await SharedPreferences.getInstance()).getString('chat_history')!);
      expect(
          stored.map((m) => m.content), ['Hi, I am Felix', 'Привет, ты тут?']);
      expect(stored.where((m) => m.sender == MessageSender.assistant),
          hasLength(1),
          reason: 'only the greeting: no reply was made up');
    });

    test('a question left without a reply shows as failed after a restart',
        () async {
      SharedPreferences.setMockInitialValues({
        'chat_history': ChatMessage.encodeMessages([
          ChatMessage(
              id: 'g',
              content: 'Hi, I am Felix',
              sender: MessageSender.assistant,
              timestamp: DateTime(2026)),
          ChatMessage(
              id: 'q',
              content: 'How do I get faster at 5K?',
              sender: MessageSender.user,
              timestamp: DateTime(2026, 1, 1, 0, 1)),
        ]),
      });
      final notifier = notifierFor(backend);

      final messages = await loaded(notifier);

      expect(messages.last.id, 'q');
      expect(messages.last.failure, ChatFailure.interrupted);

      backend.handler = FakeBackend.streaming(['Intervals once a week.']);
      await notifier.retry();
      expect(notifier.state.requireValue.map((m) => m.content), [
        'Hi, I am Felix',
        'How do I get faster at 5K?',
        'Intervals once a week.',
      ]);
      expect(notifier.state.requireValue.any((m) => m.isFailed), isFalse);
    });

    test('a reply that arrives after the chat was reloaded is shown', () async {
      final release = Completer<void>();
      backend.handler = (response) async {
        response.write('${jsonEncode({'delta': 'Easy'})}\n');
        await response.flush();
        await release.future;
        response.write('${jsonEncode({'delta': ' pace.'})}\n');
        response.write('${jsonEncode({'done': true})}\n');
      };
      final notifier = notifierFor(backend);
      final greeting = await loaded(notifier);

      final sending = notifier.sendMessage('How fast?');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final question = notifier.state.requireValue
          .firstWhere((m) => m.content == 'How fast?');
      // A sync stores the chat again while Felix is still replying.
      notifier.applySynced([...greeting, question]);
      release.complete();
      await sending;

      expect(notifier.state.requireValue.map((m) => m.content),
          ['Hi, I am Felix', 'How fast?', 'Easy pace.']);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('chat_history'), contains('Easy pace.'));
    });

    test('a synced reply clears the failed mark and Retry does nothing',
        () async {
      backend.handler = FakeBackend.error(503, 'down');
      final notifier = notifierFor(backend);
      final greeting = await loaded(notifier);
      await notifier.sendMessage('Plan my week');
      final question = notifier.state.requireValue.last;
      expect(question.isFailed, isTrue);
      final requests = backend.requests;

      final reply = ChatMessage(
          id: 'r',
          content: 'Mon: legs',
          sender: MessageSender.assistant,
          timestamp: DateTime(2030));
      notifier.applySynced(
          [...greeting, question.copyWith(clearFailure: true), reply]);

      final shown = notifier.state.requireValue;
      expect(shown.map((m) => m.content),
          ['Hi, I am Felix', 'Plan my week', 'Mon: legs']);
      expect(shown.any((m) => m.isFailed), isFalse);

      await notifier.retry();
      expect(notifier.state.requireValue.map((m) => m.content),
          ['Hi, I am Felix', 'Plan my week', 'Mon: legs']);
      expect(backend.requests, requests, reason: 'nothing was sent');
    });

    test('a failed question that is still last stays failed after a sync',
        () async {
      backend.handler = FakeBackend.error(503, 'down');
      final notifier = notifierFor(backend);
      final greeting = await loaded(notifier);
      await notifier.sendMessage('Plan my week');
      final question = notifier.state.requireValue.last;

      notifier
          .applySynced([...greeting, question.copyWith(clearFailure: true)]);

      expect(notifier.state.requireValue.last.id, question.id);
      expect(notifier.state.requireValue.last.isFailed, isTrue);
    });

    test('old canned offline replies are dropped from stored and synced chats',
        () async {
      const canned =
          'Thanks for sharing! I\'ll help you create a personalized plan based on your goals.';
      ChatMessage msg(String id, String text, MessageSender who, int min) =>
          ChatMessage(
              id: id,
              content: text,
              sender: who,
              timestamp: DateTime(2026, 1, 1, 0, min));
      final history = [
        msg('g', 'Hi, I am Felix', MessageSender.assistant, 0),
        msg('q', 'hello', MessageSender.user, 1),
        msg('m', canned, MessageSender.assistant, 2),
        msg('u', canned, MessageSender.user, 3),
      ];
      SharedPreferences.setMockInitialValues(
          {'chat_history': ChatMessage.encodeMessages(history)});
      final notifier = notifierFor(backend);

      final messages = await loaded(notifier);
      expect(messages.map((m) => m.id), ['g', 'q', 'u'],
          reason: 'only Felix\'s canned turn goes; the user\'s own text stays');

      notifier.applySynced(history);
      expect(notifier.state.requireValue.map((m) => m.id), ['g', 'q', 'u']);
    });

    test('a new message after a failed one keeps the earlier question',
        () async {
      backend.handler = FakeBackend.error(503, 'down');
      final notifier = notifierFor(backend);
      await loaded(notifier);
      await notifier.sendMessage('first');
      backend.handler = FakeBackend.streaming(['ok']);

      await notifier.sendMessage('second');

      final messages = notifier.state.requireValue;
      expect(messages.map((m) => m.content),
          ['Hi, I am Felix', 'first', 'second', 'ok']);
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

  group('chat context sent to the backend', () {
    ChatMessage message(
      String content,
      MessageSender sender, {
      bool isStreaming = false,
    }) =>
        ChatMessage(
          id: content,
          content: content,
          sender: sender,
          timestamp: DateTime(2026),
          isStreaming: isStreaming,
        );

    Future<List<ChatMessage>> loaded(ChatNotifier notifier) async {
      while (notifier.state.valueOrNull == null) {
        await Future<void>.delayed(Duration.zero);
      }
      return notifier.state.requireValue;
    }

    test('request body carries topic, profile and history', () async {
      backend.handler = FakeBackend.streaming(['ok']);
      final api = ChatApiService(baseUrl: backend.baseUrl);

      await api
          .streamMessage(
            'And protein?',
            'c1',
            topic: 'gym',
            profile: {'name': 'Misha', 'weightKg': 82},
            history: [
              {'role': 'user', 'content': 'I want to bulk'},
              {'role': 'assistant', 'content': 'Eat in a surplus.'},
            ],
            language: 'ru',
          )
          .toList();

      expect(backend.bodies.single, {
        'message': 'And protein?',
        'conversationId': 'c1',
        'topic': 'gym',
        'profile': {'name': 'Misha', 'weightKg': 82},
        'history': [
          {'role': 'user', 'content': 'I want to bulk'},
          {'role': 'assistant', 'content': 'Eat in a surplus.'},
        ],
        'language': 'ru',
      });
    });

    test('old-style requests and empty profiles stay minimal', () async {
      backend.handler = FakeBackend.streaming(['ok']);
      final api = ChatApiService(baseUrl: backend.baseUrl);

      await api.streamMessage('hi', 'c1').toList();
      await api.streamMessage('hi', 'c1', profile: const {}).toList();

      expect(backend.bodies[0], {'message': 'hi', 'conversationId': 'c1'});
      expect(backend.bodies[1], {'message': 'hi', 'conversationId': 'c1'});
    });

    test('the repository sends the context only when it has something',
        () async {
      backend.handler = FakeBackend.streaming(['ok']);
      final api = ChatApiService(baseUrl: backend.baseUrl);

      await ChatRepository(api, context: () => {'date': '2026-10-20'})
          .streamMessage('hi')
          .toList();
      await ChatRepository(api, context: () => {}).streamMessage('hi').toList();

      expect(backend.bodies[0]['context'], {'date': '2026-10-20'});
      expect(backend.bodies[1].containsKey('context'), isFalse);
    });

    test('history skips streaming and empty messages', () {
      final history = ChatMessage.toApiHistory([
        message('Hi, I am Felix', MessageSender.assistant),
        message('Plan my week', MessageSender.user),
        message('Mon: legs', MessageSender.assistant),
        message('  ', MessageSender.user),
        message('Typing...', MessageSender.assistant, isStreaming: true),
      ]);

      expect(history, [
        {'role': 'assistant', 'content': 'Hi, I am Felix'},
        {'role': 'user', 'content': 'Plan my week'},
        {'role': 'assistant', 'content': 'Mon: legs'},
      ]);
    });

    test('history keeps only the most recent 20 messages', () {
      final history = ChatMessage.toApiHistory([
        for (var i = 0; i < 30; i++)
          message(
              'm$i', i.isEven ? MessageSender.user : MessageSender.assistant),
      ]);

      expect(history, hasLength(20));
      expect(history.first['content'], 'm10');
      expect(history.last['content'], 'm29');
    });

    test('profile payload parses numbers and omits empty fields', () {
      expect(
        ChatRepository.profilePayload(UserProfile(
          name: ' Misha ',
          surname: 'B',
          age: '27',
          weight: '82,5 kg',
          height: '181',
        )),
        {'name': 'Misha', 'age': 27, 'weightKg': 82.5, 'heightCm': 181},
      );
      expect(
        ChatRepository.profilePayload(UserProfile(
          name: '',
          surname: '',
          age: '',
          weight: 'heavy',
          height: '',
        )),
        isEmpty,
      );
      expect(ChatRepository.profilePayload(null), isEmpty);
    });

    test('profile payload carries goal, experience and sports', () {
      expect(
        ChatRepository.profilePayload(UserProfile(
          name: 'Misha',
          surname: '',
          age: '',
          weight: '',
          height: '',
          goal: 'Build muscle and strength',
          experience: 'Beginner',
          sports: const ['Gym', 'Running'],
        )),
        {
          'name': 'Misha',
          'goal': 'Build muscle and strength',
          'experience': 'Beginner',
          'sports': ['Gym', 'Running'],
        },
      );
    });

    test('trainer chat sends its topic, the profile and prior turns only',
        () async {
      SharedPreferences.setMockInitialValues({
        'user_name': 'Misha',
        'user_surname': 'B',
        'user_age': '27',
        'user_weight': '82',
        'user_height': '181',
      });
      final topic = AssistantTopic.forSport(Sport.gym);
      final notifier = ChatNotifier(
        ChatRepository(
          ChatApiService(baseUrl: backend.baseUrl),
          profileRepository: ProfileRepository(),
          topic: topic.apiTopic,
          historyKey: topic.historyKey,
          conversationKey: topic.conversationKey,
          greeting: () => const ['Hey, I am your gym trainer'],
        ),
      );
      await loaded(notifier);

      backend.handler = FakeBackend.streaming(['Push, pull, legs.']);
      await notifier.sendMessage('Give me a split');

      // A failed reply must not leak into the next request's history.
      backend.handler = FakeBackend.error(503, 'Ollama is not running');
      await notifier.sendMessage('How much protein?');
      expect(notifier.state.requireValue.last.isFailed, isTrue);

      backend.handler = FakeBackend.streaming(['About 130-180 g.']);
      await notifier.retry();

      expect(backend.bodies, hasLength(3));
      final first = backend.bodies[0];
      expect(first['topic'], 'gym');
      expect(first['profile'], {
        'name': 'Misha',
        'age': 27,
        'weightKg': 82,
        'heightCm': 181,
      });
      expect(first['message'], 'Give me a split');
      expect(first['history'], [
        {'role': 'assistant', 'content': 'Hey, I am your gym trainer'},
      ]);

      final expectedHistory = [
        {'role': 'assistant', 'content': 'Hey, I am your gym trainer'},
        {'role': 'user', 'content': 'Give me a split'},
        {'role': 'assistant', 'content': 'Push, pull, legs.'},
      ];
      for (final body in backend.bodies.skip(1)) {
        expect(body['message'], 'How much protein?');
        expect(body['history'], expectedHistory);
      }
    });

    test('app assistant sends the "app" topic', () async {
      backend.handler = FakeBackend.streaming(['Hi!']);
      final notifier = ChatNotifier(
        ChatRepository(
          ChatApiService(baseUrl: backend.baseUrl),
          profileRepository: ProfileRepository(),
          greeting: () => const ['Hi, I am Felix'],
        ),
      );
      await loaded(notifier);

      await notifier.sendMessage('Hello');

      final body = backend.bodies.single;
      expect(body['topic'], 'app');
      expect(body.containsKey('profile'), isFalse,
          reason: 'no profile saved yet');
      expect(body['history'], [
        {'role': 'assistant', 'content': 'Hi, I am Felix'},
      ]);
    });
  });

  group('auth', () {
    test('sends the access token as a Bearer header', () async {
      backend.handler = FakeBackend.streaming(['ok']);
      var calls = 0;
      final api = ChatApiService(
        baseUrl: backend.baseUrl,
        accessToken: () async => 'token-${++calls}',
      );

      await api.streamMessage('hi', 'c1').toList();
      await api.streamMessage('hi again', 'c1').toList();

      expect(backend.authorizations, ['Bearer token-1', 'Bearer token-2'],
          reason: 'the token is read fresh for every request');
    });

    test('sends no header when signed out or Supabase is off', () async {
      backend.handler = FakeBackend.streaming(['ok']);

      await ChatApiService(baseUrl: backend.baseUrl)
          .streamMessage('a', 'c')
          .toList();
      await ChatApiService(
        baseUrl: backend.baseUrl,
        accessToken: () async => null,
      ).streamMessage('b', 'c').toList();
      await ChatApiService(
        baseUrl: backend.baseUrl,
        accessToken: () async => throw StateError('refresh failed'),
      ).streamMessage('c', 'c').toList();

      expect(backend.authorizations, [null, null, null]);
    });

    test('401 asks the user to sign in again', () async {
      backend.handler =
          FakeBackend.error(401, 'Invalid access token (bad signature).');
      final api = ChatApiService(
        baseUrl: backend.baseUrl,
        accessToken: () async => 'stale',
      );

      expect(
        api.streamMessage('hi', 'c1').toList(),
        throwsA(isA<ChatException>()
            .having((e) => e.failure, 'failure', ChatFailure.signInAgain)),
      );
    });

    test('429 asks the user to slow down', () async {
      backend.handler = FakeBackend.error(429, 'Too many requests');
      final api = ChatApiService(baseUrl: backend.baseUrl);

      expect(
        api.streamMessage('hi', 'c1').toList(),
        throwsA(isA<ChatException>()
            .having((e) => e.failure, 'failure', ChatFailure.tooFast)),
      );
    });

    test('a 401 reply fails the message and can be retried', () async {
      backend.handler = FakeBackend.error(401, 'expired');
      final notifier = ChatNotifier(
        ChatRepository(
          ChatApiService(
              baseUrl: backend.baseUrl, accessToken: () async => 't'),
          greeting: () => const ['Hi, I am Felix'],
        ),
      );
      while (notifier.state.valueOrNull == null) {
        await Future<void>.delayed(Duration.zero);
      }

      await notifier.sendMessage('Plan my week');

      final last = notifier.state.requireValue.last;
      expect(last.content, 'Plan my week');
      expect(last.failure, ChatFailure.signInAgain);
    });
  });
}
