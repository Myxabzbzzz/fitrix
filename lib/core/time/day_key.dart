/// Local midnight of [t]'s calendar day.
DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// The stored key of [t]'s local calendar day: "2026-10-12".
String dayKey(DateTime t) => '${t.year.toString().padLeft(4, '0')}-'
    '${t.month.toString().padLeft(2, '0')}-'
    '${t.day.toString().padLeft(2, '0')}';
