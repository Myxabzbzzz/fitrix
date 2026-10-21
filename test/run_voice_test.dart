import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitrix/features/running/presentation/run_recorder.dart';
import 'package:fitrix/features/running/presentation/run_voice.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

class FakeSpeaker implements Speaker {
  FakeSpeaker(this.available, {this.failLanguages = const {}});

  final Set<String> available;
  final Set<String> failLanguages;
  int prepares = 0;
  final spoken = <({String text, String language})>[];

  @override
  Future<Set<String>> languages() async => available;

  @override
  Future<void> prepare() async => prepares++;

  @override
  Future<bool> speak(String text, {required String language}) async {
    if (failLanguages.contains(language)) return false;
    spoken.add((text: text, language: language));
    return true;
  }
}

class Rig {
  Rig(Set<String> available, String app, {Set<String> failLanguages = const {}})
      : speaker = FakeSpeaker(available, failLanguages: failLanguages),
        events = StreamController<RunEvent>.broadcast(sync: true) {
    voice = RunVoice(speaker, events.stream, appLanguage: () => app);
  }

  final FakeSpeaker speaker;
  final StreamController<RunEvent> events;
  late final RunVoice voice;

  Future<void> send(RunEvent e) async {
    events.add(e);
    await pumpEventQueue();
  }
}

AppLocalizations l(String code) => lookupAppLocalizations(Locale(code));

void main() {
  group('pickVoiceLanguage', () {
    test('app language when the device has a voice for it', () {
      expect(pickVoiceLanguage('es', {'en', 'ru', 'es'}), 'es');
      expect(pickVoiceLanguage('uz', {'en', 'ru', 'uz'}), 'uz');
    });
    test('uzbek without a voice falls back to russian, then english', () {
      expect(pickVoiceLanguage('uz', {'en', 'ru'}), 'ru');
      expect(pickVoiceLanguage('uz', {'en'}), 'en');
    });
    test('other languages without a voice: english', () {
      expect(pickVoiceLanguage('es', {'en', 'ru'}), 'en');
      expect(pickVoiceLanguage('es', {'en'}), 'en');
      expect(pickVoiceLanguage('ru', {'en'}), 'en');
    });
    test('nothing available still answers english', () {
      expect(pickVoiceLanguage('ru', {}), 'en');
    });
  });

  group('spoken words', () {
    test('russian plurals', () {
      final ru = l('ru');
      expect(spokenDuration(ru, const Duration(minutes: 16, seconds: 35)),
          '16 минут 35 секунд');
      expect(spokenDuration(ru, const Duration(minutes: 21, seconds: 1)),
          '21 минута 1 секунда');
      expect(spokenPace(ru, 292), '4 минуты 52 секунды на километр');
    });
    test('english', () {
      final en = l('en');
      expect(spokenDuration(en, const Duration(minutes: 16, seconds: 35)),
          '16 minutes 35 seconds');
      expect(spokenDuration(en, const Duration(minutes: 1)), '1 minute');
      expect(spokenDuration(en, const Duration(seconds: 45)), '45 seconds');
      expect(spokenDuration(en, Duration.zero), '0 seconds');
      expect(spokenPace(en, 292), '4 minutes 52 seconds per kilometre');
    });
    test('a run over an hour speaks hours', () {
      expect(
          spokenDuration(
              l('en'), const Duration(hours: 1, minutes: 2, seconds: 3)),
          '1 hour 2 minutes 3 seconds');
      expect(spokenDuration(l('ru'), const Duration(hours: 2, minutes: 5)),
          '2 часа 5 минут');
      expect(spokenDuration(l('en'), const Duration(hours: 1)), '1 hour');
    });
    test('spanish and uzbek', () {
      expect(spokenDuration(l('es'), const Duration(minutes: 3, seconds: 1)),
          '3 minutos 1 segundo');
      expect(spokenDuration(l('uz'), const Duration(minutes: 3, seconds: 1)),
          '3 daqiqa 1 soniya');
    });
  });

  group('FlutterTtsSpeaker', () {
    test('sets the audio category before switching on the shared instance',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final tts = _FakeTts();
      final speaker = FlutterTtsSpeaker(tts);
      await speaker.prepare();
      expect(tts.calls, [
        'category playback duckOthers+mixWithOthers+interruptSpokenAudioAndMixWithOthers voicePrompt',
        'shared true',
        'await true',
        'category playback duckOthers+mixWithOthers+interruptSpokenAudioAndMixWithOthers voicePrompt',
        'shared true',
      ]);
    });

    test('speaks in the device locale and finishes on cancel', () async {
      final tts = _FakeTts();
      final speaker = FlutterTtsSpeaker(tts);
      expect(await speaker.languages(), {'en', 'es', 'ru'});
      var done = false;
      final f = speaker.speak('hola', language: 'es').then((v) => done = v);
      await pumpEventQueue();
      expect(tts.calls, containsAllInOrder(['lang es-MX', 'speak hola']));
      expect(done, isFalse);
      tts.cancel!();
      await f;
      expect(done, isTrue);
    });

    test('a failed setLanguage returns false and does not speak', () async {
      final tts = _FakeTts()..languageResult = 0;
      final speaker = FlutterTtsSpeaker(tts);
      expect(await speaker.speak('hola', language: 'es'), isFalse);
      expect(tts.calls.where((c) => c.startsWith('speak')), isEmpty);
    });
  });

  group('RunVoice', () {
    test('uzbek app with russian voice available speaks russian text in ru',
        () async {
      final r = await Future.value(Rig({'en', 'ru'}, 'uz'));
      await r.send(const RunStarted());
      await r.send(const RunPaused());
      await r.send(const RunResumed());
      await r.send(const KmReached(1, Duration(minutes: 6), 360, 360));
      await r.send(const RunFinished(5200, Duration(minutes: 31), 357));
      expect(r.speaker.spoken, hasLength(5));
      expect(r.speaker.spoken.map((s) => s.language).toSet(), {'ru'});
      expect(r.speaker.spoken.first.text, l('ru').runVoiceStart);
    });

    test('uzbek app with only english speaks english', () async {
      final r = Rig({'en'}, 'uz');
      await r.send(const RunStarted());
      await r.send(const RunPaused());
      expect(r.speaker.spoken.map((s) => s.language).toSet(), {'en'});
      expect(r.speaker.spoken.map((s) => s.text), ['Run started.', 'Paused.']);
    });

    test('uzbek voice present: uzbek text', () async {
      final r = Rig({'en', 'ru', 'uz'}, 'uz');
      await r.send(const RunResumed());
      expect(r.speaker.spoken.single,
          (text: l('uz').runVoiceResume, language: 'uz'));
    });

    test('a kilometre in russian: one speak with the words', () async {
      final r = Rig({'en', 'ru'}, 'ru');
      await r.send(
          const KmReached(3, Duration(minutes: 16, seconds: 35), 292, 331));
      expect(r.speaker.spoken, hasLength(1));
      expect(r.speaker.spoken.single.language, 'ru');
      expect(
        r.speaker.spoken.single.text,
        'Километр 3. Время 16 минут 35 секунд. '
        'Последний километр 4 минуты 52 секунды на километр. '
        'Средний темп 5 минут 31 секунда на километр.',
      );
    });

    test('finish speaks distance, time and pace; without pace omits it',
        () async {
      final r = Rig({'en'}, 'en');
      await r.send(
          const RunFinished(5234, Duration(minutes: 31, seconds: 2), 356));
      await r.send(const RunFinished(30, Duration(seconds: 20), null));
      expect(
          r.speaker.spoken[0].text,
          'Run finished. 5.2 kilometres in 31 minutes 2 seconds. '
          'Average 5 minutes 56 seconds per kilometre.');
      expect(r.speaker.spoken[1].text,
          'Run finished. 0.0 kilometres in 20 seconds.');
    });

    test('pause, resume, start and finish each speak once', () async {
      final r = Rig({'en'}, 'en');
      await r.send(const RunStarted());
      await r.send(const RunPaused());
      await r.send(const RunResumed());
      await r.send(const RunFinished(1000, Duration(minutes: 6), 360));
      expect(r.speaker.spoken, hasLength(4));
    });

    test('phrases queue in order and a failing speaker does not stop it',
        () async {
      final speaker = _FlakySpeaker();
      final events = StreamController<RunEvent>.broadcast(sync: true);
      RunVoice(speaker, events.stream, appLanguage: () => 'en');
      events.add(const RunStarted());
      events.add(const RunPaused());
      events.add(const RunResumed());
      await pumpEventQueue();
      expect(speaker.spoken, ['Run started.', 'Resumed.']);
    });

    test('app spanish without a spanish voice speaks english', () async {
      final r = Rig({'en', 'ru'}, 'es');
      await r.send(const RunPaused());
      expect(r.speaker.spoken.single, (text: 'Paused.', language: 'en'));
    });

    test('a language the engine refuses falls back, text re-rendered',
        () async {
      final r = Rig({'en', 'ru', 'es'}, 'es', failLanguages: {'es'});
      await r.send(const RunPaused());
      expect(r.speaker.spoken.single, (text: 'Paused.', language: 'en'));
      final u = Rig({'en', 'ru', 'uz'}, 'uz', failLanguages: {'uz'});
      await u.send(const RunPaused());
      expect(u.speaker.spoken.single,
          (text: l('ru').runVoicePause, language: 'ru'));
    });

    test('run start prepares the audio session', () async {
      final r = Rig({'en'}, 'en');
      await r.send(const RunStarted());
      await r.send(const RunPaused());
      expect(r.speaker.prepares, 1);
    });

    test('a phrase that never completes does not block the next ones',
        () async {
      final speaker = _HangingSpeaker();
      final events = StreamController<RunEvent>.broadcast(sync: true);
      RunVoice(speaker, events.stream,
          appLanguage: () => 'en',
          timeoutFor: (_) => const Duration(milliseconds: 20));
      events.add(const RunStarted());
      events.add(const RunPaused());
      events.add(const RunResumed());
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(speaker.spoken, ['Run started.', 'Paused.', 'Resumed.']);
    });

    test('russian finish keeps the time in the nominative', () async {
      final r = Rig({'ru'}, 'ru');
      await r.send(
          const RunFinished(5234, Duration(minutes: 31, seconds: 1), 356));
      expect(
          r.speaker.spoken.single.text,
          'Пробежка завершена. 5,2 километра. Время 31 минута 1 секунда. '
          'Средний темп 5 минут 56 секунд на километр.');
    });

    test('dispose stops listening', () async {
      final r = Rig({'en'}, 'en');
      r.voice.dispose();
      await r.send(const RunStarted());
      expect(r.speaker.spoken, isEmpty);
    });
  });
}

class _FlakySpeaker implements Speaker {
  final spoken = <String>[];

  @override
  Future<Set<String>> languages() async => {'en'};

  @override
  Future<void> prepare() async {}

  @override
  Future<bool> speak(String text, {required String language}) async {
    if (text == 'Paused.') throw StateError('engine hiccup');
    spoken.add(text);
    return true;
  }
}

/// The first phrase never completes, like a cancelled utterance.
class _HangingSpeaker implements Speaker {
  final spoken = <String>[];

  @override
  Future<Set<String>> languages() async => {'en'};

  @override
  Future<void> prepare() async {}

  @override
  Future<bool> speak(String text, {required String language}) {
    final first = spoken.isEmpty;
    spoken.add(text);
    return first ? Completer<bool>().future : Future.value(true);
  }
}

class _FakeTts extends Fake implements FlutterTts {
  final calls = <String>[];
  Object? languageResult = 1;
  VoidCallback? cancel;
  ErrorHandler? error;

  @override
  Future<dynamic> setIosAudioCategory(
    IosTextToSpeechAudioCategory category,
    List<IosTextToSpeechAudioCategoryOptions> options, [
    IosTextToSpeechAudioMode mode = IosTextToSpeechAudioMode.defaultMode,
  ]) async {
    calls.add('category ${category.name} '
        '${options.map((o) => o.name).join('+')} ${mode.name}');
  }

  @override
  Future<dynamic> setSharedInstance(bool sharedSession) async =>
      calls.add('shared $sharedSession');

  @override
  Future<dynamic> awaitSpeakCompletion(bool awaitCompletion) async =>
      calls.add('await $awaitCompletion');

  @override
  void setCancelHandler(VoidCallback callback) => cancel = callback;

  @override
  void setErrorHandler(ErrorHandler handler) => error = handler;

  @override
  Future<dynamic> get getLanguages async => ['en-US', 'es-MX', 'ru-RU'];

  @override
  Future<dynamic> setLanguage(String language) async {
    calls.add('lang $language');
    return languageResult;
  }

  @override
  Future<dynamic> speak(String text, {bool focus = false}) {
    calls.add('speak $text');
    return Completer<dynamic>().future;
  }
}
