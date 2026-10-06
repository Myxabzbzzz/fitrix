import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/theme/app_colors.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/widgets/fitrix_logo.dart';
import 'package:fitrix/features/auth/data/account_service.dart';
import 'package:fitrix/features/auth/data/auth_failure.dart';
import 'package:fitrix/features/auth/presentation/providers/auth_provider.dart';
import 'package:fitrix/features/auth/presentation/widgets/code_input.dart';

/// Sign in with email: enter the address, then the 6-digit code from the
/// email. New addresses get an account automatically.
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
  String? _error;

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
      setState(() => _error = AuthFailure.invalidEmail.message);
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
          SnackBar(content: Text('We sent a new code to $email')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = AuthFailure.from(e).message);
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
        _error = AuthFailure.from(e, verifying: true).message;
      });
      _focusCode();
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
          _verifiedUserId = userId;
          _error = AuthFailure.from(e).kind == AuthFailureKind.network
              ? "You're signed in, but your profile couldn't be loaded. "
                  'Check your connection and try again.'
              : "You're signed in, but your profile couldn't be loaded. "
                  'Please try again.';
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
        content: Text(
          'Sign in with $provider is coming soon. '
          'Please use your email for now.',
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
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
          const SizedBox(height: 40),
          const Center(child: FitrixLogo(fontSize: 36)),
          const SizedBox(height: 60),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: palette.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );

  Widget _errorText(String? error) => AnimatedSize(
        duration: const Duration(milliseconds: 150),
        child: error == null
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  error,
                  key: const Key('sign-in-error'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.error,
                    height: 1.4,
                  ),
                ),
              ),
      );

  Widget _primaryButton(String label, VoidCallback? onPressed) => SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: _busy ? null : onPressed,
          child: _busy
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
    // Onboarded but the session ended (signed out elsewhere, revoked).
    final signingBackIn = ref.read(appSessionProvider).onboardingComplete &&
        ref.read(authGatewayProvider) != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        signingBackIn
            ? _title(palette, 'Sign in again',
                'Your session has ended. Enter your email to continue.')
            : _title(palette, 'Create an account',
                'Enter your email to sign up for this app'),
        const SizedBox(height: 40),
        AutofillGroup(
          child: TextField(
            key: const Key('email-input'),
            controller: _emailController,
            enabled: !_busy,
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
        const SizedBox(height: 20),
        _primaryButton('Continue', _continueWithEmail),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider(color: palette.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or',
                style: TextStyle(fontSize: 14, color: palette.textSecondary),
              ),
            ),
            Expanded(child: Divider(color: palette.border)),
          ],
        ),
        const SizedBox(height: 24),
        _socialButton(
          palette,
          icon: Icons.g_mobiledata,
          label: 'Continue with Google',
          onPressed: () => _comingSoon('Google'),
        ),
        const SizedBox(height: 12),
        _socialButton(
          palette,
          icon: Icons.apple,
          label: 'Continue with Apple',
          onPressed: () => _comingSoon('Apple'),
        ),
        const SizedBox(height: 24),
        Text.rich(
          textAlign: TextAlign.center,
          TextSpan(
            style: TextStyle(fontSize: 12, color: palette.textSecondary),
            children: const [
              TextSpan(text: 'By clicking continue, you agree to our '),
              TextSpan(
                text: 'Terms of Service',
                style: TextStyle(decoration: TextDecoration.underline),
              ),
              TextSpan(text: ' and '),
              TextSpan(
                text: 'Privacy Policy',
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _socialButton(
    AppPalette palette, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) =>
      SizedBox(
        height: 54,
        child: OutlinedButton.icon(
          onPressed: _busy ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: palette.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: Icon(icon, size: 24, color: palette.textPrimary),
          label: Text(
            label,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );

  Widget _buildCodeStep(BuildContext context) {
    final palette = AppPalette.of(context);
    final profileLoadFailed = _verifiedUserId != null;
    final cooldown = _cooldownLeft > 0
        ? '${_cooldownLeft ~/ 60}:${(_cooldownLeft % 60).toString().padLeft(2, '0')}'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(
          palette,
          'Check your email',
          'Enter the ${SignInScreen.codeLength}-digit code we sent to\n$_email',
        ),
        const SizedBox(height: 40),
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
        const SizedBox(height: 20),
        if (profileLoadFailed)
          _primaryButton(
            'Try again',
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
              'Continue',
              _codeController.text.length == SignInScreen.codeLength
                  ? () => _verify(_codeController.text)
                  : null,
            ),
          ),
        const SizedBox(height: 16),
        if (!profileLoadFailed)
          TextButton(
            onPressed: _busy || cooldown != null
                ? null
                : () => _sendCode(_email, switchToCodeStep: false),
            child: Text(
              cooldown == null ? 'Resend code' : 'Resend code in $cooldown',
            ),
          ),
        TextButton(
          onPressed: _busy ? null : _changeEmail,
          child: const Text('Change email'),
        ),
        const SizedBox(height: 8),
        Text(
          "Can't find it? Check your spam folder.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: palette.textSecondary),
        ),
      ],
    );
  }
}
