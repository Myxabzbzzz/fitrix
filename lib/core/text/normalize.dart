/// The form in which names (exercises, foods) are compared: trimmed, lower case.
String normalizeName(String name) => name.trim().toLowerCase();

/// The form in which search text is compared: trimmed, lower case, «ё» as
/// «е» and the apostrophe variants (' ` ʻ ʼ ‘ ’) as one. For search only;
/// identity matching stays on [normalizeName].
String searchFold(String s) => s
    .trim()
    .toLowerCase()
    .replaceAll('ё', 'е')
    .replaceAll(RegExp("[‘’ʻʼ`']"), "'");
