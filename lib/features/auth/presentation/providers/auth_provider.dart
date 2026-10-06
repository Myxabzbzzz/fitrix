import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/features/auth/data/account_service.dart';
import 'package:fitrix/features/auth/data/auth_gateway.dart';
import 'package:fitrix/features/auth/data/repositories/auth_repository.dart';

/// Email-code sign-in. Null in local-only mode (no Supabase, e.g. tests);
/// overridden in the root ProviderScope.
final authGatewayProvider = Provider<AuthGateway?>((ref) => null);

/// Account ↔ local data glue (sign-in outcome, profile upload, sign-out).
/// Null in local-only mode; overridden in the root ProviderScope.
final accountServiceProvider = Provider<AccountService?>((ref) => null);

/// Local-only mode: remembers the email typed on the sign-in screen.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Email shown on the About me screen: the signed-in account's, or in
/// local-only mode the one typed during onboarding.
final accountEmailProvider = FutureProvider<String?>((ref) async {
  final account = ref.watch(accountServiceProvider);
  if (account != null) return account.email;
  return ref.read(authRepositoryProvider).getEmail();
});
