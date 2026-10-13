import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// On-device dictation, behind a small interface so tests never reach the
/// platform channels.
abstract class SpeechService {
  /// Asks for microphone and speech permission on first use. False when it
  /// was denied or recognition is unavailable on this device.
  Future<bool> initialize();

  /// Locale ids the device can recognise (e.g. `en_US`, `ru-RU`).
  Future<List<String>> locales();

  /// Starts listening. [onResult] gets the whole phrase so far each time it
  /// changes. [onStopped] fires when listening ends (silence, error or
  /// [stop]).
  Future<void> listen({
    required String? localeId,
    required void Function(String text) onResult,
    required VoidCallback onStopped,
  });

  Future<void> stop();
}

/// Dictation locale for the app language. uz-UZ is used only when the device
/// lists it, otherwise Russian. Returns the id exactly as the device lists
/// it, or null when the device doesn't list the wanted locale at all (the
/// recogniser then uses its default).
String? speechLocaleFor(String language, Iterable<String> available) {
  String norm(String id) => id.replaceAll('-', '_').toLowerCase();
  String? find(String wanted) {
    for (final id in available) {
      if (norm(id) == norm(wanted)) return id;
    }
    return null;
  }

  switch (language) {
    case 'ru':
      return find('ru-RU');
    case 'es':
      return find('es-ES');
    case 'uz':
      return find('uz-UZ') ?? find('ru-RU');
    default:
      return find('en-US');
  }
}

class PlatformSpeechService implements SpeechService {
  final SpeechToText _stt = SpeechToText();
  bool _ready = false;
  VoidCallback? _onStopped;

  @override
  Future<bool> initialize() async {
    if (_ready) return true;
    try {
      _ready = await _stt.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _notifyStopped();
          }
        },
        onError: (_) => _notifyStopped(),
      );
    } catch (e) {
      debugPrint('Speech recognition unavailable: $e');
      _ready = false;
    }
    return _ready;
  }

  void _notifyStopped() {
    final cb = _onStopped;
    _onStopped = null;
    cb?.call();
  }

  @override
  Future<List<String>> locales() async =>
      [for (final l in await _stt.locales()) l.localeId];

  @override
  Future<void> listen({
    required String? localeId,
    required void Function(String text) onResult,
    required VoidCallback onStopped,
  }) async {
    _onStopped = onStopped;
    await _stt.listen(
      onResult: (r) => onResult(r.recognizedWords),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        localeId: localeId,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Future<void> stop() async {
    await _stt.stop();
    _notifyStopped();
  }
}

final speechServiceProvider =
    Provider<SpeechService>((ref) => PlatformSpeechService());
