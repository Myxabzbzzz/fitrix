
import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/features/profile/data/models/profile_row.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

String aboutMeGoalLabel(AppLocalizations l10n, String goal) {
  final i = AppConstants.fitnessGoals.indexOf(goal);
  return switch (i) {
    0 => l10n.aboutGoalBuild,
    1 => l10n.aboutGoalEndurance,
    2 => l10n.aboutGoalLose,
    3 => l10n.aboutGoalHealthy,
    4 => l10n.aboutGoalTrack,
    _ => goal,
  };
}

String aboutMeLevelLabel(AppLocalizations l10n, String level) =>
    switch (level) {
      'Beginner' => l10n.programLevelBeginner,
      'Intermediate' => l10n.programLevelMedium,
      'Advanced' => l10n.programLevelAdvanced,
      _ => level,
    };

String aboutMeErrorText(AppLocalizations l10n, ProfileError e) {
  return switch (e.kind) {
    ProfileErrorKind.nameRequired => l10n.profileErrNameRequired,
    ProfileErrorKind.nameTooLong => l10n.profileErrNameTooLong,
    ProfileErrorKind.surnameTooLong => l10n.profileErrSurnameTooLong,
    ProfileErrorKind.ageRequired => l10n.profileErrAgeRequired,
    ProfileErrorKind.ageWhole => l10n.profileErrAgeWhole,
    ProfileErrorKind.ageRange => l10n.profileErrAgeRange(e.min, e.max),
    ProfileErrorKind.weightRequired => l10n.profileErrWeightRequired,
    ProfileErrorKind.weightNumber => l10n.profileErrWeightNumber,
    ProfileErrorKind.weightRange => l10n.profileErrWeightRange(e.min, e.max),
    ProfileErrorKind.heightRequired => l10n.profileErrHeightRequired,
    ProfileErrorKind.heightNumber => l10n.profileErrHeightNumber,
    ProfileErrorKind.heightRange => l10n.profileErrHeightRange(e.min, e.max),
  };
}
