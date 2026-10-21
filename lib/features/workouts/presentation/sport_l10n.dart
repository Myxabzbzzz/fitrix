import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Localized sport names. [Sport.label] stays English for the backend
/// (assistant prompts, stored data); screens show these instead.
extension SportL10n on Sport {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
        Sport.gym => l10n.sportGym,
        Sport.fitness => l10n.sportFitness,
        Sport.cycling => l10n.sportCycling,
        Sport.running => l10n.sportRunning,
        Sport.football => l10n.sportFootball,
        Sport.winterSports => l10n.sportWinterSports,
      };

  /// The big uppercase label on the My workouts tiles.
  String localizedTileLabel(AppLocalizations l10n) => switch (this) {
        Sport.winterSports => l10n.sportWinterSportsTile,
        _ => localizedLabel(l10n).toUpperCase(),
      };

  /// The label of the button that begins a workout of this sport: football
  /// is logged after the game rather than started.
  String actionLabel(AppLocalizations l10n) =>
      this == Sport.football ? l10n.footballLog : l10n.gymStart;
}
