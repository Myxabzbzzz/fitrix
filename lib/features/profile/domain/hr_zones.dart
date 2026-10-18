/// One heart-rate zone. [high] is exclusive and equals the next zone's
/// [low]; the last Karvonen zone's [high] is the max HR itself, and the last
/// Friel zone has no upper bound ([high] is null).
class HrZone {
  const HrZone(this.name, this.low, this.high);

  /// "Z1", "Z5a"... The descriptive label is localized by the screen.
  final String name;
  final int low;
  final int? high;

  /// Karvonen display: "125–139" (the mock shows shared boundaries).
  String get karvonenRange => '$low–$high';

  /// Friel display: "< 146", "155–162", "≥ 183".
  String frielRange({required bool first}) {
    final h = high;
    if (h == null) return '≥ $low';
    if (first) return '< $h';
    return '$low–${h - 1}';
  }

  @override
  bool operator ==(Object other) =>
      other is HrZone &&
      other.name == name &&
      other.low == low &&
      other.high == high;

  @override
  int get hashCode => Object.hash(name, low, high);

  @override
  String toString() => 'HrZone($name, $low, $high)';
}

/// 50–60, 60–70, 70–80, 80–90, 90–100 % of heart-rate reserve.
List<HrZone> karvonenZones(int rest, int max) {
  int at(int pct) => (rest + (max - rest) * pct / 100).round();
  const cuts = [50, 60, 70, 80, 90, 100];
  return [
    for (var i = 0; i < 5; i++)
      HrZone('Z${i + 1}', at(cuts[i]), i == 4 ? max : at(cuts[i + 1])),
  ];
}

/// Friel: <85, 85–89, 90–94, 95–99, 100–102, 103–106, >106 % of LTHR.
List<HrZone> frielZones(int lthr) {
  int at(int pct) => (lthr * pct / 100).round();
  const cuts = [85, 90, 95, 100, 103, 106];
  const names = ['Z1', 'Z2', 'Z3', 'Z4', 'Z5a', 'Z5b', 'Z5c'];
  return [
    for (var i = 0; i < 7; i++)
      HrZone(
        names[i],
        i == 0 ? 0 : at(cuts[i - 1]),
        i == 6 ? null : at(cuts[i]),
      ),
  ];
}

/// Tanaka estimate of max HR.
int tanakaMaxHr(int age) => (208 - 0.7 * age).round();
