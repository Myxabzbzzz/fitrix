// Two-device sync check against the local Supabase stack (real network).
//
// Skipped unless FITRIX_SUPABASE_IT=1. Needs `supabase start` (API on
// 55321, Mailpit on 55324):
//   FITRIX_SUPABASE_IT=1 flutter test test/sync_supabase_it_test.dart
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/supabase/supabase_config.dart';
import 'package:fitrix/core/supabase/supabase_providers.dart';
import 'package:fitrix/core/sync/sync_providers.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/data/services/chat_api_service.dart';
import 'package:fitrix/features/chat/presentation/providers/chat_provider.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/data/workout_catalog.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';

const _apiUrl = 'http://127.0.0.1:55321';
const _mailpit = 'http://127.0.0.1:55324';

final _enabled = Platform.environment['FITRIX_SUPABASE_IT'] == '1';

/// Stands in for the Node backend so Felix "replies" without an LLM.
class FakeFelix {
  late final HttpServer _server;

  String get baseUrl => 'http://127.0.0.1:${_server.port}';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((request) async {
      final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
      request.response.headers.contentType =
          ContentType('application', 'x-ndjson', charset: 'utf-8');
      request.response
        ..write('${jsonEncode({'delta': 'Re: '})}\n')
        ..write('${jsonEncode({'delta': body['message']})}\n')
        ..write('${jsonEncode({'done': true})}\n');
      await request.response.close();
    });
  }

  Future<void> stop() => _server.close(force: true);
}

Future<Object?> _getJson(String url) async {
  final client = HttpClient();
  try {
    final response = await (await client.getUrl(Uri.parse(url))).close();
    final text = await utf8.decoder.bind(response).join();
    return jsonDecode(text);
  } finally {
    client.close();
  }
}

Future<List<Map<String, dynamic>>> _mails(String email) async {
  final json = await _getJson(
    '$_mailpit/api/v1/search?query=${Uri.encodeQueryComponent('to:$email')}',
  ) as Map<String, dynamic>;
  return (json['messages'] as List).cast<Map<String, dynamic>>();
}

/// Signs in like the app does: email OTP, code read from Mailpit.
Future<SupabaseClient> _signIn(String email) async {
  final client = SupabaseClient(
    _apiUrl,
    SupabaseConfig.publishableKey,
    authOptions: const AuthClientOptions(
      authFlowType: AuthFlowType.implicit,
      autoRefreshToken: false,
    ),
  );
  final seen = {for (final m in await _mails(email)) m['ID']};
  // The same address may ask for a code at most once a second.
  for (var attempt = 1;; attempt++) {
    try {
      await client.auth.signInWithOtp(email: email);
      break;
    } on AuthApiException catch (e) {
      if (e.statusCode != '429' || attempt == 10) rethrow;
      await Future<void>.delayed(const Duration(milliseconds: 1500));
    }
  }

  final deadline = DateTime.now().add(const Duration(seconds: 20));
  String? code;
  while (code == null) {
    if (DateTime.now().isAfter(deadline)) throw StateError('No OTP mail');
    await Future<void>.delayed(const Duration(milliseconds: 250));
    for (final mail in await _mails(email)) {
      if (seen.contains(mail['ID'])) continue;
      final full = await _getJson('$_mailpit/api/v1/message/${mail['ID']}')
          as Map<String, dynamic>;
      final text = '${full['HTML']} ${full['Text']}';
      code = RegExp(r'>\s*(\d{6})\s*<').firstMatch(text)?.group(1) ??
          RegExp(r'\b(\d{6})\b').firstMatch(text)?.group(1);
      if (code != null) break;
    }
  }
  await client.auth.verifyOTP(email: email, token: code, type: OtpType.email);
  return client;
}

/// One install: own storage, provider container and Supabase session.
class Device {
  Device._(this.name, this.client, this.prefs, this.container);

  final String name;
  final SupabaseClient client;
  final SharedPreferences prefs;
  final ProviderContainer container;

  static Future<Device> signIn(
      String name, String email, FakeFelix felix) async {
    final client = await _signIn(email);
    // A fresh SharedPreferences instance; other devices keep theirs.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      supabaseClientProvider.overrideWithValue(client),
      chatApiServiceProvider
          .overrideWithValue(ChatApiService(baseUrl: felix.baseUrl)),
    ]);
    final device = Device._(name, client, prefs, container);
    // The engine starts once the auth stream reports the user.
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (container.read(syncEngineProvider) == null) {
      if (DateTime.now().isAfter(deadline)) throw StateError('No engine');
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    await device.sync();
    return device;
  }

  T read<T>(ProviderListenable<T> provider) => container.read(provider);

  String get userId => client.auth.currentUser!.id;

  Future<void> sync() async {
    await read(syncEngineProvider)!.sync();
    final status = read(syncStatusProvider);
    print('[$name] synced: pending=${status.pending} error=${status.error}');
    expect(status.error, isNull);
    expect(status.pending, 0);
  }

  List<String> get plans =>
      [for (final p in read(workoutTemplatesProvider)) p.name];

  List<String> get history =>
      [for (final w in read(workoutHistoryProvider)) '${w.name} ${w.id}'];

  List<String> chat(AssistantTopic topic) {
    final raw = prefs.getString(topic.historyKey);
    if (raw == null) return const [];
    return [
      for (final m in ChatMessage.decodeMessages(raw))
        '${m.sender.name}: ${m.content.split('\n').first}',
    ];
  }

  Future<void> say(AssistantTopic topic, String text) async {
    final provider = chatMessagesProviderFor(topic);
    while (read(provider).valueOrNull == null) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await read(provider.notifier).sendMessage(text);
    expect(read(provider).requireValue.last.content, 'Re: $text');
  }

  Future<void> dispose() async {
    container.dispose();
    await client.dispose();
  }
}

void main() {
  test(
    'two devices and a second user against local Supabase',
    () async {
      final felix = FakeFelix();
      await felix.start();
      addTearDown(felix.stop);

      final stamp = DateTime.now().millisecondsSinceEpoch;
      final email = 'sync-$stamp@fitrix.test';
      final otherEmail = 'sync-$stamp-other@fitrix.test';
      final gym = AssistantTopic.all.firstWhere((t) => t.sport == Sport.gym);

      // --- Device A: plans, a finished workout, chats -----------------------
      final a = await Device.signIn('A', email, felix);
      addTearDown(a.dispose);
      print('user $email = ${a.userId}');

      final plans = a.read(workoutTemplatesProvider.notifier)
        ..add(Sport.running, 'IT Plan')
        ..add(Sport.gym, 'IT Temp');
      WorkoutTemplate named(Device d, String name) =>
          d.read(workoutTemplatesProvider).firstWhere((p) => p.name == name);
      plans
        ..update(named(a, 'IT Plan').copyWith(name: 'IT Plan v2'))
        ..remove(named(a, 'IT Temp').id)
        ..remove('gym-back-triceps');
      a.read(activeWorkoutProvider.notifier)
        ..start(WorkoutCatalog.defaults.first)
        ..setKg(0, 0, 30)
        ..toggleSet(0, 0);
      expect(a.read(activeWorkoutProvider.notifier).finish(), isTrue);
      await a.say(AssistantTopic.app, 'Build muscle and strength');
      await a.say(gym, 'Plan my leg day');
      await a.sync();

      print('[A] plans:   ${a.plans}');
      print('[A] history: ${a.history}');
      print('[A] app:     ${a.chat(AssistantTopic.app)}');
      print('[A] gym:     ${a.chat(gym)}');

      // --- Device B: same user, fresh install -------------------------------
      final b = await Device.signIn('B', email, felix);
      addTearDown(b.dispose);
      print('[B] plans:   ${b.plans}');
      print('[B] history: ${b.history}');
      print('[B] app:     ${b.chat(AssistantTopic.app)}');
      print('[B] gym:     ${b.chat(gym)}');

      expect(b.plans, a.plans);
      expect(b.plans, contains('IT Plan v2'));
      expect(b.plans, isNot(contains('IT Temp')));
      expect(b.plans, isNot(contains('Back and Triceps')));
      expect(b.history, a.history);
      expect(b.history, hasLength(1));
      expect(
          b.read(workoutHistoryProvider).single.exercises.single.sets.single.kg,
          30);
      expect(b.chat(AssistantTopic.app), a.chat(AssistantTopic.app));
      expect(b.chat(gym), a.chat(gym));
      expect(b.chat(gym).last, 'assistant: Re: Plan my leg day');

      // --- An edit and a message on B reach A -------------------------------
      b
          .read(workoutTemplatesProvider.notifier)
          .update(named(b, 'IT Plan v2').copyWith(name: 'IT Plan v3 (from B)'));
      await b.say(AssistantTopic.app, 'Hello from B');
      await b.sync();
      await a.sync();
      print('[A] plans after B edit: ${a.plans}');
      print('[A] app after B chat:   ${a.chat(AssistantTopic.app)}');
      expect(a.plans, contains('IT Plan v3 (from B)'));
      expect(a.plans, b.plans);
      expect(a.chat(AssistantTopic.app), b.chat(AssistantTopic.app));
      expect(
        a.read(chatMessagesProvider).requireValue.map((m) => m.content),
        contains('Hello from B'),
        reason: "A's open chat updates in place",
      );

      // --- Another user sees none of it -------------------------------------
      final c = await Device.signIn('C', otherEmail, felix);
      addTearDown(c.dispose);
      print('user $otherEmail = ${c.userId}');
      print('[C] plans:   ${c.plans}');
      print('[C] history: ${c.history}');
      expect(c.plans, [for (final p in WorkoutCatalog.defaults) p.name]);
      expect(c.history, isEmpty);
      for (final topic in AssistantTopic.all) {
        expect(c.chat(topic), isEmpty);
      }
      for (final table in [
        'workout_templates',
        'completed_workouts',
        'chat_messages',
      ]) {
        // RLS: C can't read A's rows even when asking for them.
        final ofA = await c.client.from(table).select('id').eq(
              'user_id',
              a.userId,
            );
        final own = await c.client.from(table).select('id');
        print('[C] $table: rows of A visible=${ofA.length}, '
            'own rows=${own.length}');
        expect(ofA, isEmpty);
      }
    },
    skip: _enabled ? false : 'Set FITRIX_SUPABASE_IT=1 (needs supabase start)',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
