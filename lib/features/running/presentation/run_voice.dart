import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';

import 'package:fitrix/features/language/presentation/providers/language_provider.dart';
import 'package:fitrix/features/running/presentation/run_recorder.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Text to speech. [language] is a base code ('en', 'ru', 'uz', 'es').
abstract class Speaker {
  /// Base codes of the languages the device can speak.
  Future<Set<String>> languages();

  /// Speaks [text] and completes when it has been said.
  Future<void> speak(String text, {required String language});
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

  Future<void> _configure() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _tts.setSharedInstance(true);
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
    }
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> _ready() => _configured ??= _configure().catchError((Object e) {
        // Try again on the next phrase.
        _configured = null;
        throw e;
      });

  @override
  Future<Set<String>> languages() async {
    await _ready();
    final raw = await _tts.getLanguages;
    return {
      if (raw is List)
        for (final code in raw)
          code.toString().split(RegExp('[-_]')).first.toLowerCase(),
    };
  }

  @override
  Future<void> speak(String text, {required String language}) async {
    await _ready();
    await _tts.setLanguage(_ttsLocales[language] ?? language);
    await _tts.speak(text, focus: true);
  }
}

final speakerProvider = Provider<Speaker>((ref) => FlutterTtsSpeaker());

/// The language to speak in: the app's, or when the device has no voice for
/// it Russian if it has that, else English. Uzbek text is never read by a
/// Russian voice: the Russian fallback speaks the Russian text.
String pickVoiceLanguage(String appLanguage, Set<String> available) {
  if (available.contains(appLanguage)) return appLanguage;
  if (available.contains('ru')) return 'ru';
  return 'en';
}

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

/// Says what happens in a run: start, pause, resume, every kilometre, finish.
class RunVoice {
  RunVoice(
    this._speaker,
    Stream<RunEvent> events, {
    required String Function() appLanguage,
  }) : _appLanguage = appLanguage {
    _sub = events.listen(_onEvent);
  }

  final Speaker _speaker;
  final String Function() _appLanguage;
  late final StreamSubscription<RunEvent> _sub;

  /// Phrases are said one after another, never over each other.
  Future<void> _queue = Future.value();

  void _onEvent(RunEvent e) {
    _queue = _queue.then((_) => _say(e)).catchError((Object _) {});
  }

  Future<void> _say(RunEvent e) async {
    final available = await _speaker.languages();
    final language = pickVoiceLanguage(_appLanguage(), available);
    final l10n = lookupAppLocalizations(Locale(language));
    final text = switch (e) {
      RunStarted() => l10n.runVoiceStart,
      RunPaused() => l10n.runVoicePause,
      RunResumed() => l10n.runVoiceResume,
      KmReached() => l10n.runVoiceKm(
          e.km,
          spokenDuration(l10n, e.total),
          spokenPace(l10n, e.lastKmSecPerKm),
          spokenPace(l10n, e.avgSecPerKm),
        ),
      RunFinished() => _finish(l10n, language, e),
    };
    await _speaker.speak(text, language: language);
  }

  String _finish(AppLocalizations l10n, String language, RunFinished e) {
    final distance = NumberFormat('0.0', language).format(e.meters / 1000);
    final time = spokenDuration(l10n, e.moving);
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
  );
  ref.onDispose(voice.dispose);
  return voice;
});
