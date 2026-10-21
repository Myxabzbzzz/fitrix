import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/pill_selector.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/start_workout.dart';
import 'package:fitrix/core/widgets/sync_refresh.dart';
import 'package:fitrix/features/workouts/presentation/widgets/sport_coach_card.dart';
import 'package:fitrix/features/workouts/presentation/widgets/workouts_grid.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:fitrix/features/workouts/presentation/sport_l10n.dart';

/// Workouts of one sport ("Gym"): the sport's plans, marked with the day
/// the week plan has them on.
class SportWorkoutsScreen extends ConsumerStatefulWidget {
  final Sport sport;

  const SportWorkoutsScreen({super.key, required this.sport});

  @override
  ConsumerState<SportWorkoutsScreen> createState() =>
      _SportWorkoutsScreenState();
}

class _SportWorkoutsScreenState extends ConsumerState<SportWorkoutsScreen> {
  late Sport _sport = widget.sport;

  Future<void> _start(WorkoutTemplate template) =>
      startWorkout(context, ref, template);

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenTitle(_sport.localizedLabel(l10n)),
            PillSelector<Sport>(
              items: Sport.values,
              selected: _sport,
              labelOf: (s) => s.localizedLabel(l10n),
              onSelected: (s) => s == Sport.running || s == Sport.football
                  ? context.pushReplacement(AppRouter.sportWorkouts(s))
                  : setState(() => _sport = s),
            ),
            Expanded(
              child: SyncRefresh(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    WorkoutsGrid(
                      sport: _sport,
                      actionLabel: _sport.actionLabel(l10n),
                      onAction: _start,
                    ),
                    SportCoachCard(sport: _sport, onStart: _start),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
