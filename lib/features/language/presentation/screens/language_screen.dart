import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/theme/app_colors.dart';
import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/features/language/presentation/providers/language_provider.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = ref.watch(selectedLanguageProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // FITRIX Logo
              _buildLogo(),

              const SizedBox(height: 60),

              // Globe Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.language,
                  size: 50,
                  color: AppColors.textOnDark,
                ),
              ),

              const SizedBox(height: 40),

              // Language Selection Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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

              // Continue Button
              _buildContinueButton(context, selectedLanguage != null),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return RichText(
      text: const TextSpan(
        children: [
          TextSpan(
            text: 'FI',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
              letterSpacing: 2,
            ),
          ),
          TextSpan(
            text: 'TRIX',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 2,
            ),
          ),
        ],
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
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          ref.read(selectedLanguageProvider.notifier).setLanguage(code);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.buttonSelected : AppColors.buttonUnselected,
          foregroundColor: isSelected ? AppColors.textOnDark : AppColors.textPrimary,
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

  Widget _buildContinueButton(BuildContext context, bool enabled) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: enabled
            ? () {
                context.go(AppRouter.signIn);
              }
            : null,
        child: const Text('Continue'),
      ),
    );
  }
}
