import 'package:flutter/widgets.dart';
import 'package:fitrix/features/chat/data/services/speech_service.dart';

/// Fills [text] with what the user dictates. Tap to start, tap again (or
/// stay silent) to stop.
class DictationController extends ChangeNotifier {
  final SpeechService _service;
  final TextEditingController text;

  /// App language code ('en', 'ru', 'uz', 'es').
  final String Function() language;

  DictationController(this._service, this.text, {required this.language});

  bool _listening = false;
  bool _starting = false;
  bool _disposed = false;

  /// Identifies the current listening session; results and stop events of
  /// an ended session are ignored.
  int _session = 0;

  bool get listening => _listening;

  /// Starts or stops dictation. Returns false when it couldn't start
  /// because permission was denied or recognition is unavailable.
  Future<bool> toggle() async {
    if (_listening) {
      await stop();
      return true;
    }
    if (_starting) return true;
    _starting = true;
    try {
      if (!await _service.initialize()) return false;
      if (_disposed) return true;
      final base = text.text.trimRight();
      final localeId = speechLocaleFor(language(), await _service.locales());
      final id = ++_session;
      _listening = true;
      notifyListeners();
      try {
        await _service.listen(
          localeId: localeId,
          onResult: (words) {
            if (id != _session || !_listening) return;
            final joined = base.isEmpty ? words : '$base $words';
            text.value = TextEditingValue(
              text: joined,
              selection: TextSelection.collapsed(offset: joined.length),
            );
          },
          onStopped: () => _ended(id),
        );
      } catch (_) {
        _ended(id);
        return false;
      }
      return true;
    } finally {
      _starting = false;
    }
  }

  /// Stops listening. Results that arrive afterwards are ignored.
  Future<void> stop() async {
    if (!_listening) return;
    _listening = false;
    _session++;
    if (!_disposed) notifyListeners();
    try {
      await _service.stop();
    } catch (_) {}
  }

  void _ended(int id) {
    if (id != _session || !_listening) return;
    _listening = false;
    _session++;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_listening) {
      _listening = false;
      _session++;
      _service.stop();
    }
    super.dispose();
  }
}
