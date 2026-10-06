import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/sync/sync_providers.dart';
import 'package:fitrix/core/theme/app_colors.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/auth/presentation/providers/auth_provider.dart';
import 'package:fitrix/features/profile/presentation/providers/profile_provider.dart';

/// Profile tab: the data entered during onboarding.
class AboutMeScreen extends ConsumerWidget {
  const AboutMeScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final account = ref.read(accountServiceProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: Text(
          account == null
              ? 'Your profile, chats and workouts are stored only on this '
                  'device and will be deleted.'
              : 'Your profile, workouts and chats are saved to your account '
                  'and will be removed from this device. Sign in with the '
                  'same email to get them back.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Grab these before signing out: it recreates the provider scope.
    final router = GoRouter.of(context);
    final session = ref.read(appSessionProvider);
    final sync = ref.read(syncEngineProvider);
    if (sync != null) {
      // Upload workouts/chats not yet on the server; offline, don't block.
      try {
        await sync.sync().timeout(const Duration(seconds: 3));
      } catch (_) {}
    }
    if (account != null) {
      // Ends the Supabase session (works offline), then clears local data.
      await account.signOut();
    } else {
      await session.signOut();
    }
    router.go(AppRouter.intro);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
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
            const ScreenTitle('About me'),
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
                  stat('Age', profile?.age, ''),
                  const SizedBox(width: 12),
                  stat('Weight', profile?.weight, ' kg'),
                  const SizedBox(width: 12),
                  stat('Height', profile?.height, ' cm'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: OutlinedButton.icon(
                onPressed: () => _signOut(context, ref),
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: palette.border),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
