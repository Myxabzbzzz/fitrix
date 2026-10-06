import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The Supabase client, or null when Supabase isn't initialized (tests, or
/// if initialization failed). Code using it must keep working locally when
/// it's null. Overridden in `main()` after `Supabase.initialize`.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) => null);

/// The signed-in Supabase user, updated on sign-in, sign-out and token
/// refresh. Null when signed out or when Supabase isn't available.
final currentUserProvider = StreamProvider<User?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return Stream.value(null);
  return client.auth.onAuthStateChange
      .map((state) => state.session?.user)
      .distinct((a, b) => a?.id == b?.id);
});
