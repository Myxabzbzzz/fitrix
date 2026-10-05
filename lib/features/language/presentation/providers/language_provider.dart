import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/features/language/data/repositories/language_repository.dart';

final languageRepositoryProvider = Provider<LanguageRepository>((ref) {
  return LanguageRepository();
});

final selectedLanguageProvider = StateNotifierProvider<LanguageNotifier, String?>((ref) {
  return LanguageNotifier(ref.read(languageRepositoryProvider));
});

class LanguageNotifier extends StateNotifier<String?> {
  final LanguageRepository _repository;

  LanguageNotifier(this._repository) : super(null) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final language = await _repository.getLanguage();
    state = language ?? 'en';
  }

  Future<void> setLanguage(String languageCode) async {
    await _repository.saveLanguage(languageCode);
    state = languageCode;
  }
}
