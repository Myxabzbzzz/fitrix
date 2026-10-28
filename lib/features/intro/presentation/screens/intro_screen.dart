import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/widgets/fitrix_logo.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // FITRIX Logo
              const FitrixLogo(fontSize: 48),

              const SizedBox(height: AppSpacing.lg),

              // Subtitle
              _buildSubtitle(context),

              const Spacer(flex: 3),

              // Start Button
              _buildStartButton(context),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final palette = AppPalette.of(context);
    final base = AppText.headingS.copyWith(
      color: palette.textPrimary,
      fontWeight: FontWeight.w400,
    );
    final accent = TextStyle(color: palette.accent);

    return Column(
      children: [
        Text.rich(
          textAlign: TextAlign.center,
          style: base,
          TextSpan(
            children: [
              const TextSpan(text: 'The '),
              TextSpan(text: 'F', style: accent),
              const TextSpan(text: 'itness '),
              TextSpan(text: 'Ma', style: accent),
              const TextSpan(text: 'trix'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text.rich(
          textAlign: TextAlign.center,
          style: base,
          TextSpan(
            children: [
              const TextSpan(text: 'Based on '),
              TextSpan(text: 'Art', style: accent),
              const TextSpan(text: 'ificial '),
              TextSpan(text: 'i', style: accent),
              const TextSpan(text: 'ntelligence'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: const ButtonStyle(
            minimumSize: WidgetStatePropertyAll(Size.fromHeight(54))),
        onPressed: () {
          context.go(AppRouter.language);
        },
        child: Text(AppLocalizations.of(context).introStart),
      ),
    );
  }
}
