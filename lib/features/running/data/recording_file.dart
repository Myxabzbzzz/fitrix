import 'dart:convert';
import 'dart:io';

import 'run_track.dart';

/// The fixes of the recording in progress, one JSON line each:
/// `[lat,lng,alt,accuracy,msSinceStart]`. Appending a few fixes every
/// few seconds costs the same on hour 1 and hour 8, unlike re-encoding the
/// whole day. A line cut off by a crash is skipped when reading.
class RecordingFile {
  RecordingFile(this.file);

  final File file;

  /// Empties the file (a new recording).
  void reset() {
    file.createSync(recursive: true);
    file.writeAsStringSync('', flush: true);
  }

  /// Adds [fixes] at the end.
  void append(Iterable<RunPoint> fixes, DateTime startedAt) {
    final out = StringBuffer();
    for (final p in fixes) {
      out.writeln(_line(p, startedAt));
    }
    if (out.isEmpty) return;
    file.writeAsStringSync(out.toString(), mode: FileMode.append, flush: true);
  }

  /// Replaces the content with [fixes].
  void rewrite(Iterable<RunPoint> fixes, DateTime startedAt) {
    file.createSync(recursive: true);
    file.writeAsStringSync('', flush: true);
    append(fixes, startedAt);
  }

  /// The fixes in the file, and whether a broken line was left out.
  ({List<RunPoint> fixes, bool damaged}) read(DateTime startedAt) {
    final fixes = <RunPoint>[];
    var damaged = false;
    final String text;
    try {
      text = file.readAsStringSync();
    } catch (_) {
      return (fixes: fixes, damaged: false);
    }
    final base = startedAt.millisecondsSinceEpoch;
    var from = 0;
    while (from < text.length) {
      var to = text.indexOf('\n', from);
      final complete = to >= 0;
      if (!complete) to = text.length;
      final line = text.substring(from, to);
      from = to + 1;
      if (line.isEmpty) continue;
      try {
        final a = jsonDecode(line) as List;
        if (!complete) throw const FormatException('cut off');
        fixes.add(RunPoint(
          lat: (a[0] as num).toDouble(),
          lng: (a[1] as num).toDouble(),
          alt: (a[2] as num?)?.toDouble(),
          accuracy: (a[3] as num).toDouble(),
          at: DateTime.fromMillisecondsSinceEpoch(base + (a[4] as num).toInt()),
        ));
      } catch (_) {
        damaged = true;
      }
    }
    return (fixes: fixes, damaged: damaged);
  }

  void delete() {
    try {
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
  }

  static String _line(RunPoint p, DateTime startedAt) => jsonEncode([
        p.lat,
        p.lng,
        p.alt,
        p.accuracy,
        p.at.millisecondsSinceEpoch - startedAt.millisecondsSinceEpoch,
      ]);
}
