import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';

import 'package:fitrix/features/language/presentation/providers/language_provider.dart';
import 'package:fitrix/features/running/data/activity_kind.dart';
import 'package:fitrix/features/running/data/activity_settings.dart';
import 'package:fitrix/features/running/presentation/run_recorder.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Text to speech. [language] is a base code ('en', 'ru', 'uz', 'es').
abstract class Speaker {
  /// Base codes of the languages the device can speak.
  Future<Set<String>> languages();

  /// Gets the audio session ready for a run (so speech lowers other audio
  /// instead of stopping it). Called when a run starts.
  Future<void> prepare();

  /// Speaks [text] and completes when it has been said, was cancelled or
  /// failed. Returns false, without speaking, when the device cannot
  /// switch to a voice for [language].
  Future<bool> speak(String text, {required String language});

  /// Cuts off the phrase being spoken, if any.
  Future<void> stop();
}

const _ttsLocales = {
  'en': 'en-US',
  'ru': 'ru-RU',
  'uz': 'uz-UZ',
  'es': 'es-ES',
};

/// The device's speech engine. On iOS it plays on the shared audio session
/// in the playback category, so it is heard with the screen locked (the app
/// has the `audio` background mode) and lowers other audio, such as music,
/// while it talks instead of stopping it.
class FlutterTtsSpeaker implements Speaker {
  FlutterTtsSpeaker([FlutterTts? tts]) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  Future<void>? _configured;
  Completer<void>? _current;

  /// Cancel/error events still to come for phrases [stop] cut off; they must
  /// not complete the phrase that follows.
  int _staleEvents = 0;

  /// The device's own locale string for each base code, from [languages].
  final _deviceLocales = <String, String>{};

  Future<void> _configure() async {
    await _applyAudioSession();
    await _tts.awaitSpeakCompletion(true);
    // A cancelled or failed phrase never completes the speak future.
    _tts.setCancelHandler(_onCancelOrError);
    _tts.setErrorHandler((dynamic _) => _onCancelOrError());
  }

  /// The category goes first: switching the shared instance on activates
  /// the session, and in the default category that would pause music.
  Future<void> _applyAudioSession() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    await _tts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.duckOthers,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        IosTextToSpeechAudioCategoryOptions
            .interruptSpokenAudioAndMixWithOthers,
      ],
      IosTextToSpeechAudioMode.voicePrompt,
    );
    await _tts.setSharedInstance(true);
  }

  void _onCancelOrError() {
    if (_staleEvents > 0) {
      _staleEvents--;
      return;
    }
    _finish(_current);
  }

  static void _finish(Completer<void>? c) {
    if (c != null && !c.isCompleted) c.complete();
  }

  Future<void> _ready() => _configured ??= _configure().catchError((Object e) {
        // Try again on the next phrase.
        _configured = null;
        throw e;
      });

  @override
  Future<void> prepare() async {
    await _ready();
    await _applyAudioSession();
  }

  @override
  Future<Set<String>> languages() async {
    await _ready();
    final raw = await _tts.getLanguages;
    final bases = <String>{};
    if (raw is List) {
      for (final item in raw) {
        final locale = item.toString().replaceAll('_', '-');
        final base = locale.split('-').first.toLowerCase();
        bases.add(base);
        // Prefer the locale we name; otherwise any the device has.
        if (locale == _ttsLocales[base] || !_deviceLocales.containsKey(base)) {
          _deviceLocales[base] = item.toString();
        }
      }
    }
    return bases;
  }

  @override
  Future<bool> speak(String text, {required String language}) async {
    await _ready();
    Object? set;
    try {
      set = await _tts.setLanguage(
          _deviceLocales[language] ?? _ttsLocales[language] ?? language);
    } catch (_) {
      return false;
    }
    if (set == 0 || set == false) return false;
    // flutter_tts deactivates the session after every phrase (so music comes
    // back up): set it up and activate it again, so this phrase ducks too.
    try {
      await _applyAudioSession();
    } catch (_) {
      // Speak anyway; the system may still activate the session.
    }
    // Each phrase has its own completer: a late completion of an earlier
    // phrase can only finish that phrase.
    final done = _current = Completer<void>();
    unawaited(_tts.speak(text, focus: true).then(
          (_) => _finish(done),
          onError: (Object _) => _finish(done),
        ));
    await done.future;
    return true;
  }

  @override
  Future<void> stop() async {
    final c = _current;
    _current = null;
    if (c != null && !c.isCompleted) {
      _staleEvents++;
      c.complete();
    }
    await _tts.stop();
  }
}

final speakerProvider = Provider<Speaker>((ref) => FlutterTtsSpeaker());

/// Languages to try, best first: the app's if the device has a voice for
/// it; Russian for Uzbek (never the other way round, and never Uzbek text in
/// a Russian voice); English last.
List<String> voiceLanguageChain(String appLanguage, Set<String> available) => [
      if (available.contains(appLanguage)) appLanguage,
      if (appLanguage == 'uz' && available.contains('ru')) 'ru',
      if (appLanguage != 'en' || !available.contains('en')) 'en',
    ];

/// First of [voiceLanguageChain].
String pickVoiceLanguage(String appLanguage, Set<String> available) =>
    voiceLanguageChain(appLanguage, available).first;

/// "16 minutes 35 seconds", "1 hour 2 minutes"; zero parts are left out.
String spokenDuration(AppLocalizations l10n, Duration d) {
  final total = d.inSeconds;
  final h = total ~/ 3600;
  final m = total % 3600 ~/ 60;
  final s = total % 60;
  final parts = [
    if (h > 0) l10n.runVoiceHours(h),
    if (m > 0) l10n.runVoiceMinutes(m),
    if (s > 0 || total == 0) l10n.runVoiceSeconds(s),
  ];
  return parts.join(' ');
}

/// "4 minutes 52 seconds per kilometre".
String spokenPace(AppLocalizations l10n, int secPerKm) =>
    l10n.runVoicePace(spokenDuration(l10n, Duration(seconds: secPerKm)));

ActivityKind? _runKind() => ActivityKind.run;

bool _alwaysOn(ActivityKind kind) => true;

Duration _defaultTimeout(String text) =>
    Duration(milliseconds: 5000 + text.length * 150);

/// Says what happens in a run: start, pause, resume, every kilometre, finish.
class RunVoice {
  RunVoice(
    this._speaker,
    Stream<RunEvent> events, {
    required String Function() appLanguage,
    Duration Function(String text) timeoutFor = _defaultTimeout,
    ActivityKind? Function() sessionKind = _runKind,
    bool Function(ActivityKind kind) voiceOn = _alwaysOn,
  })  : _appLanguage = appLanguage,
        _timeoutFor = timeoutFor,
        _sessionKind = sessionKind,
        _voiceOn = voiceOn {
    _sub = events.listen(_onEvent);
  }

  final Speaker _speaker;
  final String Function() _appLanguage;
  final Duration Function(String text) _timeoutFor;
  final ActivityKind? Function() _sessionKind;
  final bool Function(ActivityKind kind) _voiceOn;
  late final StreamSubscription<RunEvent> _sub;

  /// Kind of the latest session; a finish comes after the session is gone.
  ActivityKind _lastKind = ActivityKind.run;

  /// Phrases are said one after another, never over each other.
  Future<void> _queue = Future.value();

  void _onEvent(RunEvent e) {
    // Decided when it happens, not when its turn in the queue comes.
    final kind = switch (e) {
      DistanceReached() => ActivityKind.ride,
      SkiDescentDone() => ActivityKind.ski,
      KmReached() => ActivityKind.run,
      _ => _sessionKind() ?? _lastKind,
    };
    _lastKind = kind;
    if (!_voiceOn(kind)) return;
    _queue = _queue.then((_) => _say(e, kind)).catchError((Object error) {
      debugPrint('Run voice: $error');
    });
  }

  Future<void> _say(RunEvent e, ActivityKind kind) async {
    if (e is RunStarted) await _speaker.prepare();
    final available = await _speaker.languages();
    for (final language in voiceLanguageChain(_appLanguage(), available)) {
      final l10n = lookupAppLocalizations(Locale(language));
      final text = _phrase(l10n, language, kind, e);
      // A phrase the engine never reports as finished must not block the
      // ones after it.
      var timedOut = false;
      final spoken = await _speaker
          .speak(text, language: language)
          .timeout(_timeoutFor(text), onTimeout: () {
        timedOut = true;
        return true;
      });
      if (timedOut) {
        // Cut it off so it cannot talk over the next phrase.
        await _speaker.stop().catchError((Object _) {});
      }
      if (spoken) return;
    }
  }

  String _phrase(AppLocalizations l10n, String language, ActivityKind kind,
          RunEvent e) =>
      switch (e) {
        RunStarted() => switch (kind) {
            ActivityKind.run => l10n.runVoiceStart,
            ActivityKind.ride => l10n.rideVoiceStart,
            ActivityKind.ski => l10n.skiVoiceStart,
          },
        RunPaused() => l10n.runVoicePause,
        RunResumed() => l10n.runVoiceResume,
        KmReached() => l10n.runVoiceKm(
            e.km,
            spokenDuration(l10n, e.total),
            spokenPace(l10n, e.lastKmSecPerKm),
            spokenPace(l10n, e.avgSecPerKm),
          ),
        RunFinished() => _finish(l10n, language, kind, e),
        DistanceReached() => l10n.rideVoiceDistance(
            NumberFormat('0.#', language).format(e.meters / 1000),
            spokenDuration(l10n, e.total),
            _kmh(language, e.lastSplitSpeed),
            _kmh(language, e.avgSpeed),
          ),
        SkiDescentDone() => l10n.skiVoiceDescent(
            e.index,
            NumberFormat('0.0', language).format(e.meters / 1000),
            e.vertical.round(),
            _kmh(language, e.maxSpeed, decimals: 0),
          ),
      };

  /// m/s as km/h.
  static String _kmh(String language, double mps, {int decimals = 1}) =>
      NumberFormat(decimals == 0 ? '0' : '0.0', language).format(mps * 3.6);

  String _finish(AppLocalizations l10n, String language, ActivityKind kind,
      RunFinished e) {
    final distance = NumberFormat('0.0', language).format(e.meters / 1000);
    final time = spokenDuration(l10n, e.moving);
    if (kind == ActivityKind.ride) {
      return l10n.rideVoiceFinish(distance, time);
    }
    if (kind == ActivityKind.ski) return l10n.skiVoiceFinish(distance, time);
    final pace = e.avgSecPerKm;
    return pace == null
        ? l10n.runVoiceFinishShort(distance, time)
        : l10n.runVoiceFinish(distance, time, spokenPace(l10n, pace));
  }

  void dispose() => _sub.cancel();
}

/// Listens to the run recorder for as long as the app is up, so the voice
/// is there when a run starts and still says "finished" after the session
/// is gone. The app root watches it.
final runVoiceProvider = Provider<RunVoice>((ref) {
  final voice = RunVoice(
    ref.read(speakerProvider),
    ref.read(runRecorderProvider.notifier).events,
    appLanguage: () => ref.read(selectedLanguageProvider),
    sessionKind: () => ref.read(runRecorderProvider)?.kind,
    voiceOn: (kind) => ref.read(activityVoiceProvider)[kind] ?? false,
  );
  ref.onDispose(voice.dispose);
  return voice;
});
