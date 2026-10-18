import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/fitrix_logo.dart';
import 'package:fitrix/features/auth/data/account_service.dart';
import 'package:fitrix/features/auth/data/auth_failure.dart';
import 'package:fitrix/features/auth/data/social_sign_in.dart';
import 'package:fitrix/features/auth/presentation/providers/auth_provider.dart';
import 'package:fitrix/features/auth/presentation/widgets/code_input.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Sign in with email: enter the address, then the 6-digit code from the
/// email. New addresses get an account automatically. "Continue with
/// Google / Apple" sign in natively when the build enables them (see
/// SocialSignInConfig) and say "coming soon" otherwise.
///
/// In local-only mode (no Supabase) the email is only remembered and
/// onboarding continues, as before accounts existed.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  /// Wait before another code can be requested.
  static const resendCooldown = Duration(seconds: 60);

  static const codeLength = 6;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

enum _Step { email, code }

class _SignInScreenState extends ConsumerState<SignInScreen> {
  static const _requestTimeout = Duration(seconds: 20);

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();

  _Step _step = _Step.email;
  String _email = '';
  bool _busy = false;

  /// An [AuthFailure] or [_ProfileLoadFailed]; shown localized.
  Object? _error;

  /// The Google / Apple sign-in in progress, for its button's spinner.
  SocialProvider? _socialBusy;

  /// Set when the code was accepted but the profile couldn't be loaded.
  String? _verifiedUserId;

  Timer? _cooldownTimer;
  int _cooldownLeft = 0;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    // Typing a new code hides the previous error.
    if (mounted &&
        _error != null &&
        _codeController.text.isNotEmpty &&
        _verifiedUserId == null) {
      setState(() => _error = null);
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownLeft = SignInScreen.resendCooldown.inSeconds;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _cooldownLeft--);
      if (_cooldownLeft <= 0) timer.cancel();
    });
  }

  Future<void> _continueWithEmail() async {
    if (_busy) return;
    final email = _emailController.text.trim();
    if (!looksLikeEmail(email)) {
      setState(() => _error = AuthFailure.invalidEmail);
      return;
    }

    final auth = ref.read(authGatewayProvider);
    if (auth == null) {
      // Local-only mode: no account, just remember the email.
      await ref.read(authRepositoryProvider).saveEmail(email);
      if (mounted) context.go(AppRouter.profile);
      return;
    }

    await _sendCode(email, switchToCodeStep: true);
  }

  Future<void> _sendCode(String email, {required bool switchToCodeStep}) async {
    final auth = ref.read(authGatewayProvider);
    if (auth == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.sendCode(email).timeout(_requestTimeout);
      if (!mounted) return;
      _codeController.clear();
      setState(() {
        _email = email;
        _verifiedUserId = null;
        if (switchToCodeStep) _step = _Step.code;
      });
      _startCooldown();
      _focusCode();
      if (!switchToCodeStep) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context).signInCodeResent(email))),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = AuthFailure.from(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify(String code) async {
    if (_busy || code.length != SignInScreen.codeLength) return;
    final auth = ref.read(authGatewayProvider);
    if (auth == null) return;
    // Read these first: once the session starts the router may already
    // move on (same account signing back in), disposing this screen.
    final router = GoRouter.of(context);
    final account = ref.read(accountServiceProvider);

    setState(() {
      _busy = true;
      _error = null;
    });
    final String userId;
    try {
      userId = await auth
          .verifyCode(email: _email, code: code)
          .timeout(_requestTimeout);
    } catch (e) {
      if (!mounted) return;
      _codeController.clear();
      setState(() {
        _busy = false;
        _error = AuthFailure.from(e, verifying: true);
      });
      _focusCode();
      return;
    }
    await _finishSignIn(userId, router, account);
  }

  /// Google or Apple: the provider's own sheet, then Supabase, then the same
  /// steps as after an email code. Cancelling the sheet changes nothing.
  Future<void> _continueWith(SocialProvider provider) async {
    if (_busy) return;
    final auth = ref.read(authGatewayProvider);
    final config = ref.read(socialSignInConfigProvider);
    final enabled = switch (provider) {
      SocialProvider.google => config.googleEnabled,
      SocialProvider.apple => config.appleEnabled,
    };
    if (auth == null || !enabled) {
      _comingSoon(provider.label);
      return;
    }

    final social = ref.read(socialSignInProvider);
    final router = GoRouter.of(context);
    final account = ref.read(accountServiceProvider);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      _busy = true;
      _socialBusy = provider;
      _error = null;
    });

    final String userId;
    try {
      final credential = switch (provider) {
        SocialProvider.google => await social.google(),
        SocialProvider.apple => await social.apple(),
      };
      if (credential == null) {
        // Cancelled by the user: back to where they were, no message.
        if (mounted) {
          setState(() {
            _busy = false;
            _socialBusy = null;
          });
        }
        return;
      }
      userId =
          await auth.signInWithIdToken(credential).timeout(_requestTimeout);
    } catch (e) {
      debugPrint('${provider.label} sign-in failed: $e');
      if (!mounted) return;
      setState(() {
        _busy = false;
        _socialBusy = null;
        _error = AuthFailure.fromSocial(e, provider: provider.label);
      });
      return;
    }
    await _finishSignIn(userId, router, account);
  }

  /// Loads the account's profile and continues to Home or onboarding.
  /// [router] and [account] are read up front: finishing sign-in may
  /// rebuild the provider scope (and this screen with it).
  Future<void> _finishSignIn(
    String userId,
    GoRouter router,
    AccountService? account,
  ) async {
    if (mounted) {
      setState(() {
        _busy = true;
        _error = null;
      });
    }

    SignInDestination destination = SignInDestination.profile;
    if (account != null) {
      try {
        destination = await account.completeSignIn(userId);
      } catch (e) {
        debugPrint('Loading profile after sign-in failed: $e');
        if (!mounted) return;
        setState(() {
          _busy = false;
          _socialBusy = null;
          _verifiedUserId = userId;
          _error = _ProfileLoadFailed(
              network: AuthFailure.from(e).kind == AuthFailureKind.network);
        });
        return;
      }
    }
    router.go(destination == SignInDestination.home
        ? AppRouter.home
        : AppRouter.profile);
  }

  /// After the next frame, once the code field is built and enabled.
  void _focusCode() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _step == _Step.code) _codeFocus.requestFocus();
    });
  }

  void _changeEmail() {
    _cooldownTimer?.cancel();
    _codeController.clear();
    setState(() {
      _step = _Step.email;
      _error = null;
      _verifiedUserId = null;
      _cooldownLeft = 0;
    });
  }

  void _comingSoon(String provider) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).signInComingSoon(provider)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _step == _Step.email
                ? KeyedSubtree(
                    key: const ValueKey('email-step'),
                    child: _buildEmailStep(context),
                  )
                : KeyedSubtree(
                    key: const ValueKey('code-step'),
                    child: _buildCodeStep(context),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _title(AppPalette palette, String title, String subtitle) => Column(
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

  String _errorMessage(AppLocalizations l10n, Object error) {
    if (error is _ProfileLoadFailed) {
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

  Widget _errorText(Object? error) => AnimatedSize(
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

  Widget _primaryButton(String label, VoidCallback? onPressed) => SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: _busy ? null : onPressed,
          // Google / Apple show their progress on their own button.
          child: _busy && _socialBusy == null
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Text(label),
        ),
      );

  Widget _buildEmailStep(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    // Onboarded but the session ended (signed out elsewhere, revoked).
    final signingBackIn = ref.read(appSessionProvider).onboardingComplete &&
        ref.read(authGatewayProvider) != null;
    final social = ref.watch(socialSignInConfigProvider);
    // Signed in with Google / Apple, but the profile didn't load.
    final profileLoadFailed = _verifiedUserId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        signingBackIn
            ? _title(palette, l10n.signInAgainTitle, l10n.signInAgainSubtitle)
            : _title(
                palette, l10n.signInCreateTitle, l10n.signInCreateSubtitle),
        const SizedBox(height: AppSpacing.xl),
        AutofillGroup(
          child: TextField(
            key: const Key('email-input'),
            controller: _emailController,
            enabled: !_busy && !profileLoadFailed,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.go,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _continueWithEmail(),
            decoration: const InputDecoration(hintText: 'name@example.com'),
          ),
        ),
        _errorText(_error),
        const SizedBox(height: AppSpacing.lg),
        if (profileLoadFailed)
          _primaryButton(
            l10n.signInTryAgain,
            () => _finishSignIn(
              _verifiedUserId!,
              GoRouter.of(context),
              ref.read(accountServiceProvider),
            ),
          )
        else
          // "Get code" when a code is actually emailed, so it can't be
          // mistaken for "Continue with Google" below.
          _primaryButton(
            ref.watch(authGatewayProvider) == null
                ? l10n.continueButton
                : l10n.signInGetCode,
            _continueWithEmail,
          ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(child: Divider(color: palette.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                l10n.signInOr,
                style:
                    AppText.bodyRegular.copyWith(color: palette.textSecondary),
              ),
            ),
            Expanded(child: Divider(color: palette.border)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _socialButton(
          palette,
          key: const Key('google-sign-in'),
          provider: SocialProvider.google,
          icon: Icons.g_mobiledata,
          enabled: !profileLoadFailed,
        ),
        // Sign in with Apple only exists on Apple devices.
        if (social.showAppleButton) ...[
          const SizedBox(height: AppSpacing.sm),
          _socialButton(
            palette,
            key: const Key('apple-sign-in'),
            provider: SocialProvider.apple,
            icon: Icons.apple,
            enabled: !profileLoadFailed,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text.rich(
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
        ),
      ],
    );
  }

  Widget _socialButton(
    AppPalette palette, {
    required Key key,
    required SocialProvider provider,
    required IconData icon,
    required bool enabled,
  }) =>
      SizedBox(
        key: key,
        height: 54,
        child: OutlinedButton.icon(
          onPressed: _busy || !enabled ? null : () => _continueWith(provider),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: palette.border),
            // Matches the themed button radius, like the controls above.
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: _socialBusy == provider
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Icon(icon, size: 24, color: palette.textPrimary),
          label: Text(
            AppLocalizations.of(context).signInContinueWith(provider.label),
            style: AppText.headingS.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );

  Widget _buildCodeStep(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final profileLoadFailed = _verifiedUserId != null;
    final cooldown = _cooldownLeft > 0
        ? '${_cooldownLeft ~/ 60}:${(_cooldownLeft % 60).toString().padLeft(2, '0')}'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(
          palette,
          l10n.signInCheckEmailTitle,
          l10n.signInCodePrompt('${SignInScreen.codeLength}', _email),
        ),
        const SizedBox(height: AppSpacing.xl),
        CodeInput(
          controller: _codeController,
          focusNode: _codeFocus,
          length: SignInScreen.codeLength,
          enabled: !profileLoadFailed,
          readOnly: _busy,
          hasError: _error != null && !profileLoadFailed,
          onCompleted: _verify,
        ),
        _errorText(_error),
        const SizedBox(height: AppSpacing.lg),
        if (profileLoadFailed)
          _primaryButton(
            l10n.signInTryAgain,
            () => _finishSignIn(
              _verifiedUserId!,
              GoRouter.of(context),
              ref.read(accountServiceProvider),
            ),
          )
        else
          // Rebuilds only the button per keystroke, not the whole screen.
          ListenableBuilder(
            listenable: _codeController,
            builder: (context, _) => _primaryButton(
              l10n.continueButton,
              _codeController.text.length == SignInScreen.codeLength
                  ? () => _verify(_codeController.text)
                  : null,
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        if (!profileLoadFailed)
          TextButton(
            onPressed: _busy || cooldown != null
                ? null
                : () => _sendCode(_email, switchToCodeStep: false),
            child: Text(
              cooldown == null
                  ? l10n.signInResend
                  : l10n.signInResendIn(cooldown),
            ),
          ),
        TextButton(
          onPressed: _busy ? null : _changeEmail,
          child: Text(l10n.signInChangeEmail),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.signInSpamNote,
          textAlign: TextAlign.center,
          style: AppText.caption.copyWith(color: palette.textSecondary),
        ),
      ],
    );
  }
}

/// The account signed in but its profile couldn't be fetched.
class _ProfileLoadFailed {
  const _ProfileLoadFailed({required this.network});
  final bool network;
}
