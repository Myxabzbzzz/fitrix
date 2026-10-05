import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/theme/app_colors.dart';
import 'package:fitrix/core/router/app_router.dart';

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
              _buildLogo(),

              const SizedBox(height: 24),

              // Subtitle
              _buildSubtitle(),

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

  Widget _buildLogo() {
    return RichText(
      text: const TextSpan(
        children: [
          TextSpan(
            text: 'FI',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
              letterSpacing: 2,
            ),
          ),
          TextSpan(
            text: 'TRIX',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w400,
            ),
            children: [
              TextSpan(text: 'The '),
              TextSpan(
                text: 'F',
                style: TextStyle(color: AppColors.secondary),
              ),
              TextSpan(text: 'itness '),
              TextSpan(
                text: 'Ma',
                style: TextStyle(color: AppColors.secondary),
              ),
              TextSpan(text: 'trix'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w400,
            ),
            children: [
              TextSpan(text: 'Based on '),
              TextSpan(
                text: 'Art',
                style: TextStyle(color: AppColors.secondary),
              ),
              TextSpan(text: 'ificial '),
              TextSpan(
                text: 'i',
                style: TextStyle(color: AppColors.secondary),
              ),
              TextSpan(text: 'ntelligence'),
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
