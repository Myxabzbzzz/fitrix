import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/widgets/fitrix_logo.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // FITRIX Logo
              const FitrixLogo(fontSize: 48),

              const SizedBox(height: 24),

              // Subtitle
              _buildSubtitle(context),

              const Spacer(flex: 3),

              // Start Button
              _buildStartButton(context),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final palette = AppPalette.of(context);
    final base = TextStyle(
      fontSize: 16,
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
        const SizedBox(height: 4),
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
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          context.go(AppRouter.language);
        },
        child: const Text('Start your journey'),
      ),
    );
  }
}
