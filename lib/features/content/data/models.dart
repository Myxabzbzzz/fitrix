class Program {
  const Program({
    required this.id,
    required this.title,
    required this.meta,
    required this.level,
    required this.sport,
    this.image,
  });

  final String id, title, meta, level, sport;
  final String? image;

  factory Program.fromJson(Map<String, dynamic> j) => Program(
        id: j['id'] as String,
        title: j['title'] as String,
        meta: j['meta'] as String,
        level: j['level'] as String,
        sport: j['sport'] as String,
        image: j['image'] as String?,
      );
}

class Article {
  const Article({
    required this.id,
    required this.tag,
    required this.title,
    required this.body,
    required this.minutes,
  });

  final String id, tag, title, body;
  final int minutes;

  factory Article.fromJson(Map<String, dynamic> j) => Article(
        id: j['id'] as String,
        tag: j['tag'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        minutes: (j['minutes'] as num).toInt(),
      );
}

class Challenge {
  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.dailyTarget,
    required this.days,
    required this.startsOn,
    required this.endsOn,
  });

  final String id, title, description, dailyTarget;
  final int days;
  final DateTime startsOn, endsOn;

  factory Challenge.fromJson(Map<String, dynamic> j) => Challenge(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String,
        dailyTarget: j['daily_target'] as String,
        days: (j['days'] as num).toInt(),
        startsOn: _date(j['starts_on'] as String),
        endsOn: _date(j['ends_on'] as String),
      );

  /// Calendar dates ('2026-10-12') as local midnight.
  static DateTime _date(String s) {
    final d = DateTime.parse(s.substring(0, 10));
    return DateTime(d.year, d.month, d.day);
  }
}

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.kind,
    required this.type,
    required this.lat,
    required this.lon,
    this.hours,
    this.note,
  });

  final String id, name, kind, type;
  final double lat, lon;
  final String? hours, note;

  factory Place.fromJson(Map<String, dynamic> j) => Place(
        id: j['id'] as String,
        name: j['name'] as String,
        kind: j['kind'] as String,
        type: j['type'] as String,
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        hours: j['hours'] as String?,
        note: j['note'] as String?,
      );
}
