import 'package:fitrix/features/checkin/data/checkin_models.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Localized names for the check-in enums and readiness copy.
extension CheckInText on AppLocalizations {
  String readinessLabel(ReadinessLabel l) => switch (l) {
        ReadinessLabel.ready => readinessReady,
        ReadinessLabel.trainLight => readinessTrainLight,
        ReadinessLabel.rest => readinessRest,
      };

  String qualityName(SleepQuality q) => switch (q) {
        SleepQuality.poor => sleepQualityPoor,
        SleepQuality.ok => sleepQualityOk,
        SleepQuality.good => sleepQualityGood,
      };

  String sorenessName(Soreness s) => switch (s) {
        Soreness.none => sorenessNone,
        Soreness.light => sorenessLight,
        Soreness.medium => sorenessMedium,
        Soreness.strong => sorenessStrong,
      };

  String areaName(BodyArea a) => switch (a) {
        BodyArea.legs => bodyLegs,
        BodyArea.back => bodyBack,
        BodyArea.chest => bodyChest,
        BodyArea.arms => bodyArms,
        BodyArea.shoulders => bodyShoulders,
      };

  String energyName(Level3 l) => switch (l) {
        Level3.low => levelLow,
        Level3.ok => levelOk,
        Level3.high => levelHigh,
      };

  String stressName(Level3 l) => switch (l) {
        Level3.low => stressLow,
        Level3.ok => stressMedium,
        Level3.high => stressHigh,
      };

  String areasText(Iterable<BodyArea> areas) => [
        for (final a in BodyArea.values)
          if (areas.contains(a)) areaName(a).toLowerCase(),
      ].join(', ');

  String sleepText(Duration d) =>
      checkinSleepDuration(d.inMinutes ~/ 60, d.inMinutes % 60);

  /// Short advice shown with the live preview in the check-in sheet.
  String checkinHint(Readiness r, CheckIn c) {
    switch (r.label) {
      case ReadinessLabel.ready:
        return c.soreness != Soreness.none && c.sore.isNotEmpty
            ? checkinHintReadySore(_cap(areasText(c.sore)))
            : checkinHintReady;
      case ReadinessLabel.trainLight:
        return checkinHintLight;
      case ReadinessLabel.rest:
        return checkinHintRest;
    }
  }

  /// Advice under the ring on the Recovery screen.
  String recoveryHint(Readiness r, CheckIn c) {
    if (r.label == ReadinessLabel.ready &&
        c.soreness != Soreness.none &&
        c.sore.isNotEmpty) {
      return recoveryHintReadySore(areasText(c.sore));
    }
    return checkinHint(r, c);
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
