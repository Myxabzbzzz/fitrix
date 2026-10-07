import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/widgets/fitrix_logo.dart';
import 'package:fitrix/features/language/presentation/providers/language_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = ref.watch(selectedLanguageProvider);
    final palette = AppPalette.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // FITRIX Logo
              const FitrixLogo(fontSize: 36),

              const SizedBox(height: 60),

              // Globe Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: palette.textPrimary,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.language,
                  size: 50,
                  color: palette.background,
                ),
              ),

              const SizedBox(height: 40),

              // Language Selection Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: palette.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: palette.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: AppConstants.languages.entries.map((entry) {
                    final isSelected = selectedLanguage == entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildLanguageButton(
                        context,
                        ref,
                        entry.key,
                        entry.value,
                        isSelected,
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Spacer(),

              // Continue Button: keeps the highlighted language even if
              // it's the device default nobody tapped.
              _buildContinueButton(context, ref, selectedLanguage),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton(
    BuildContext context,
    WidgetRef ref,
    String code,
    String label,
    bool isSelected,
  ) {
    final palette = AppPalette.of(context);

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          ref.read(selectedLanguageProvider.notifier).setLanguage(code);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? palette.accent : palette.tile,
          foregroundColor: isSelected ? Colors.white : palette.textPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton(
    BuildContext context,
    WidgetRef ref,
    String selectedLanguage,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () async {
          final router = GoRouter.of(context);
          await ref
              .read(selectedLanguageProvider.notifier)
              .setLanguage(selectedLanguage);
          router.go(AppRouter.signIn);
        },
        child: Text(AppLocalizations.of(context).continueButton),
      ),
    );
  }
}
