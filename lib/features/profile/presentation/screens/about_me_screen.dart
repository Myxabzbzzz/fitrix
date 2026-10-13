import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/auth/presentation/providers/auth_provider.dart';
import 'package:fitrix/features/profile/presentation/providers/profile_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// About me: the data entered during onboarding (opened from the Profile tab).
class AboutMeScreen extends ConsumerWidget {
  const AboutMeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider).valueOrNull;
    final email = ref.watch(accountEmailProvider).valueOrNull;

    final fullName = [profile?.name, profile?.surname]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');

    Widget stat(String label, String? value, String unit) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: palette.tile,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  value == null || value.isEmpty ? '—' : '$value$unit',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: palette.textSecondary),
                ),
              ],
            ),
          ),
        );

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            ScreenTitle(l10n.aboutMeTitle),
            const SizedBox(height: 16),
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: palette.tile,
                child: Icon(Icons.person, size: 48, color: palette.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                fullName.isEmpty ? '@theboss' : fullName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
            ),
            if (email != null && email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Center(
                child: Text(
                  email,
                  key: const Key('account-email'),
                  style: TextStyle(fontSize: 14, color: palette.textSecondary),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                children: [
                  stat(l10n.age, profile?.age, ''),
                  const SizedBox(width: 12),
                  stat(l10n.weight, profile?.weight, ' ${l10n.unitKg}'),
                  const SizedBox(width: 12),
                  stat(l10n.height, profile?.height, ' ${l10n.unitCm}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
