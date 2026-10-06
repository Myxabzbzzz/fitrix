import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitrix/core/supabase/supabase_providers.dart';
import 'package:fitrix/core/sync/remote_store.dart';
import 'package:fitrix/core/sync/supabase_remote_store.dart';
import 'package:fitrix/core/sync/sync_engine.dart';
import 'package:fitrix/core/sync/sync_local.dart';

/// Where synced data lives on the server; null in local-only mode (no
/// Supabase, e.g. in tests). Tests override it with an in-memory store.
final remoteStoreProvider = Provider<RemoteStore?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseRemoteStore(client);
});

/// Id of the signed-in user, or null.
final syncUserIdProvider = Provider<String?>(
  (ref) => ref.watch(currentUserProvider).valueOrNull?.id,
);

/// The running sync engine while a user is signed in, else null. Signing
/// in (or out, or as someone else) replaces it. Watched by [SyncBootstrap].
final syncEngineProvider = Provider<SyncEngine?>((ref) {
  final remote = ref.watch(remoteStoreProvider);
  final userId = ref.watch(syncUserIdProvider);
  if (remote == null || userId == null) return null;

  final engine = SyncEngine(
    local: SyncLocal(ref),
    remote: remote,
    userId: userId,
  );
  ref.onDispose(engine.dispose);
  engine.start();
  return engine;
});

/// Sync status for an optional indicator (e.g. "synced 2 min ago",
/// "3 changes waiting"). [SyncStatus.disabled] while signed out.
final syncStatusProvider = Provider<SyncStatus>((ref) {
  final engine = ref.watch(syncEngineProvider);
  if (engine == null) return SyncStatus.disabled;
  void update() => ref.state = engine.status.value;
  engine.status.addListener(update);
  ref.onDispose(() => engine.status.removeListener(update));
  return engine.status.value;
});

/// Keeps sync running for the app's lifetime: starts the engine when a
/// user is signed in and syncs again when the app returns to the
/// foreground. Renders [child] unchanged.
class SyncBootstrap extends ConsumerStatefulWidget {
  const SyncBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SyncBootstrap> createState() => _SyncBootstrapState();
}

class _SyncBootstrapState extends ConsumerState<SyncBootstrap> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(syncEngineProvider)?.sync(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(syncEngineProvider);
    return widget.child;
  }
}
