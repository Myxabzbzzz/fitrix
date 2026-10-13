import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/navigation/circle_reveal.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/feature_tile.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// "My workouts": a large tile per sport, each opening its list of workouts.
class MyWorkoutsScreen extends ConsumerWidget {
  const MyWorkoutsScreen({super.key});

  static const _sports = [Sport.gym, Sport.fitness, Sport.cycling];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final templates = ref.watch(workoutTemplatesProvider);
    final history = ref.watch(workoutHistoryProvider);
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));

    String caption(Sport sport) => l10n.gymTileCaption(
          templates.where((t) => t.sport == sport).length,
          history
              .where((w) => w.sport == sport && w.finishedAt.isAfter(weekAgo))
              .length,
        );

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenTitle('My workouts'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.lg),
                children: [
                  for (final sport in _sports) ...[
                    SizedBox(
                      height: 120,
                      child: Builder(
                        // The tile's own context, so the reveal starts there.
                        builder: (tileContext) => FeatureTile(
                          label: sport.tileLabel,
                          labelSize: 24,
                          imageAsset: sport.imageAsset,
                          imageWidthFactor: 0.45,
                          labelAlignment: Alignment.topLeft,
                          imageAlignment: Alignment.centerRight,
                          onTap: () => openWithReveal(
                            tileContext,
                            AppRouter.sportWorkouts(sport),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs, horizontal: AppSpacing.xxs),
                      child: Text(
                        caption(sport),
                        style: AppText.caption
                            .copyWith(color: palette.textSecondary),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
