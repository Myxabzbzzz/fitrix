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
  bool _disposed = false;
  bool get listening => _listening;

  /// Starts or stops dictation. Returns false when it couldn't start
  /// because permission was denied or recognition is unavailable.
  Future<bool> toggle() async {
    if (_listening) {
      await stop();
      return true;
    }
    if (!await _service.initialize()) return false;
    final base = text.text.trimRight();
    final localeId = speechLocaleFor(language(), await _service.locales());
    _listening = true;
    notifyListeners();
    await _service.listen(
      localeId: localeId,
      onResult: (words) {
        final joined = base.isEmpty ? words : '$base $words';
        text.value = TextEditingValue(
          text: joined,
          selection: TextSelection.collapsed(offset: joined.length),
        );
      },
      onStopped: _stopped,
    );
    return true;
  }

  Future<void> stop() async {
    if (!_listening) return;
    await _service.stop();
    _stopped();
  }

  void _stopped() {
    if (!_listening) return;
    _listening = false;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_listening) _service.stop();
    super.dispose();
  }
}
