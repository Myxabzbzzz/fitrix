import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/sync/sync_providers.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Pull down to sync with the cloud right away. [child] must be a
/// scrollable with [AlwaysScrollableScrollPhysics] so short lists can be
/// pulled too. Without an account (nothing to sync) it's just [child].
class SyncRefresh extends ConsumerWidget {
  const SyncRefresh({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(syncEngineProvider);
    if (engine == null) return child;

    return RefreshIndicator.adaptive(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        final messenger = ScaffoldMessenger.of(context);
        final failed = AppLocalizations.of(context).syncFailed;
        await engine.sync();
        if (engine.status.value.error != null) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(failed)));
        }
      },
      child: child,
    );
  }
}
