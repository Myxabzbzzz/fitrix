import 'package:flutter/material.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/fitrix_logo.dart';
import 'package:fitrix/features/auth/data/auth_failure.dart';
import 'package:fitrix/features/auth/data/social_sign_in.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// The account signed in but its profile couldn't be fetched.
class ProfileLoadFailed {
  const ProfileLoadFailed({required this.network});
  final bool network;
}

/// Logo, heading and subheading at the top of each sign-in step.
class SignInTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const SignInTitle(this.title, this.subtitle, {super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        const Center(child: FitrixLogo(fontSize: 36)),
        const SizedBox(height: AppSpacing.xl),
        Text(
          title,
          style: AppText.headingL.copyWith(color: palette.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppText.bodyRegular.copyWith(color: palette.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

String _errorMessage(AppLocalizations l10n, Object error) {
  if (error is ProfileLoadFailed) {
    return error.network
        ? l10n.signInProfileLoadOffline
        : l10n.signInProfileLoadFailed;
  }
  if (error is! AuthFailure) return l10n.signInErrUnknown;
  final provider = error.provider ?? '';
  return switch (error.kind) {
    AuthFailureKind.invalidCode => l10n.signInErrInvalidCode,
    AuthFailureKind.rateLimited => l10n.signInErrRateLimited,
    AuthFailureKind.network => l10n.signInErrNetwork,
    AuthFailureKind.invalidEmail => l10n.signInErrInvalidEmail,
    AuthFailureKind.unknown => l10n.signInErrUnknown,
    AuthFailureKind.providerDisabled =>
      l10n.signInErrProviderDisabled(provider),
    AuthFailureKind.providerUnavailable =>
      l10n.signInErrProviderUnavailable(provider),
    AuthFailureKind.socialFailed => l10n.signInErrSocialFailed(provider),
  };
}

/// The localized error line under the input; collapses when [error] is null.
class SignInError extends StatelessWidget {
  final Object? error;

  const SignInError(this.error, {super.key});

  @override
  Widget build(BuildContext context) {
    final error = this.error;
    return AnimatedSize(
      duration: const Duration(milliseconds: 150),
      child: error == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                _errorMessage(AppLocalizations.of(context), error),
                key: const Key('sign-in-error'),
                textAlign: TextAlign.center,
                style: AppText.bodyRegular
                    .copyWith(color: AppPalette.of(context).error),
              ),
            ),
    );
  }
}

/// The main action button; shows a spinner while an email request is busy.
class SignInPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  /// The Google / Apple sign-in in progress; they show their progress on
  /// their own button.
  final SocialProvider? socialBusy;

  const SignInPrimaryButton(
    this.label,
    this.onPressed, {
    super.key,
    required this.busy,
    required this.socialBusy,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: const ButtonStyle(
              minimumSize: WidgetStatePropertyAll(Size.fromHeight(54))),
          onPressed: busy ? null : onPressed,
          // Google / Apple show their progress on their own button.
          child: busy && socialBusy == null
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Text(label),
        ),
      );
}

/// "Continue with Google / Apple".
class SocialSignInButton extends StatelessWidget {
  final SocialProvider provider;
  final IconData icon;
  final bool enabled;
  final bool busy;
  final SocialProvider? socialBusy;
  final VoidCallback onPressed;

  const SocialSignInButton({
    super.key,
    required this.provider,
    required this.icon,
    required this.enabled,
    required this.busy,
    required this.socialBusy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: busy || !enabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          // At least 54 tall, growing when the label wraps (large text).
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          side: BorderSide(color: palette.border),
          // Matches the themed button radius, like the controls above.
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: socialBusy == provider
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Icon(icon, size: 24, color: palette.textPrimary),
        label: Text(
          AppLocalizations.of(context).signInContinueWith(provider.label),
          textAlign: TextAlign.center,
          style: AppText.headingS.copyWith(
            color: palette.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// A rule with "or" in the middle, between the email and social buttons.
class SignInOrDivider extends StatelessWidget {
  const SignInOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(child: Divider(color: palette.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            l10n.signInOr,
            style: AppText.bodyRegular.copyWith(color: palette.textSecondary),
          ),
        ),
        Expanded(child: Divider(color: palette.border)),
      ],
    );
  }
}

/// "By continuing you agree to the Terms and Privacy Policy".
class SignInTerms extends StatelessWidget {
  const SignInTerms({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return Text.rich(
      textAlign: TextAlign.center,
      TextSpan(
        style: AppText.caption.copyWith(color: palette.textSecondary),
        children: [
          TextSpan(text: l10n.signInTermsPrefix),
          TextSpan(
            text: l10n.signInTerms,
            style: const TextStyle(decoration: TextDecoration.underline),
          ),
          TextSpan(text: l10n.signInTermsAnd),
          TextSpan(
            text: l10n.signInPrivacy,
            style: const TextStyle(decoration: TextDecoration.underline),
          ),
          TextSpan(text: l10n.signInTermsSuffix),
        ],
      ),
    );
  }
}
