import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/features/running/presentation/run_format.dart';
import 'package:fitrix/features/running/presentation/run_recorder.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// "Run in progress · 2.30 km · Return": shown above the tab bar while a run
/// exists (recording, paused, or restored after a crash). Tap opens the live
/// run; it is the way back after leaving that screen with its arrow.
class RunInProgressBar extends ConsumerWidget {
  const RunInProgressBar({super.key});

  static const double height = 48;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meters = ref.watch(
      runRecorderProvider.select((s) => s?.track.meters),
    );
    if (meters == null) return const SizedBox.shrink();
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: height,
      child: Material(
        key: const ValueKey('run-bar'),
        color: palette.accent,
        child: InkWell(
          onTap: () => context.push(AppRouter.liveRun),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.runBarTitle(formatKm(meters, l10n.localeName)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyStrong.copyWith(color: palette.onAccent),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(l10n.runBarReturn,
                    style:
                        AppText.bodyStrong.copyWith(color: palette.onAccent)),
                Icon(Icons.chevron_right, size: 20, color: palette.onAccent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
