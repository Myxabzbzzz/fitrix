enum FootballType { match, training }

/// Formats, as stored (shown as 5×5 …).
const footballFormats = ['5x5', '6x6', '7x7', '8x8', '11x11'];

/// Positions, as stored.
const footballPositions = ['GK', 'CB', 'FB', 'CM', 'WM', 'ST'];

/// "7x7" as shown: "7×7".
String formatLabel(String format) => format.replaceAll('x', '×');

/// A logged game or training: the `match` document, its id is the id of
/// the workout it belongs to. A training has no result, goals or assists.
class MatchLog {
  const MatchLog({
    required this.type,
    required this.date,
    this.format,
    required this.minutes,
    this.position,
    this.rpe,
    this.goalsFor,
    this.goalsAgainst,
    this.goals,
    this.assists,
    this.note,
    this.templateId,
  });

  final FootballType type;

  /// When the game ended (the workout's `finishedAt`).
  final DateTime date;
  final String? format;
  final int minutes;
  final String? position;
  final int? rpe;
  final int? goalsFor, goalsAgainst, goals, assists;
  final String? note;
  final String? templateId;

  Map<String, Object?> toJson() => {
        'type': type.name,
        'date': date.toUtc().toIso8601String(),
        if (format != null) 'format': format,
        'minutes': minutes,
        if (position != null) 'position': position,
        if (rpe != null) 'rpe': rpe,
        if (goalsFor != null) 'goalsFor': goalsFor,
        if (goalsAgainst != null) 'goalsAgainst': goalsAgainst,
        if (goals != null) 'goals': goals,
        if (assists != null) 'assists': assists,
        if (note != null) 'note': note,
        if (templateId != null) 'templateId': templateId,
      };

  /// Throws on anything malformed; the store and the sync skip such docs.
  factory MatchLog.fromJson(Map<String, Object?> j) => MatchLog(
        type: FootballType.values.byName(j['type']! as String),
        date: DateTime.parse(j['date']! as String),
        format: j['format'] as String?,
        minutes: (j['minutes']! as num).toInt(),
        position: j['position'] as String?,
        rpe: (j['rpe'] as num?)?.toInt(),
        goalsFor: (j['goalsFor'] as num?)?.toInt(),
        goalsAgainst: (j['goalsAgainst'] as num?)?.toInt(),
        goals: (j['goals'] as num?)?.toInt(),
        assists: (j['assists'] as num?)?.toInt(),
        note: j['note'] as String?,
        templateId: j['templateId'] as String?,
      );
}
