import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fitrix/core/i18n/catalog_overlay.dart';

/// An asset bundle with only the overlay files given (path -> JSON object);
/// every other asset is missing. Counts the reads.
class FixtureBundle extends CachingAssetBundle {
  FixtureBundle(Map<String, Object> files)
      : _files = {for (final e in files.entries) e.key: jsonEncode(e.value)};

  final Map<String, String> _files;
  final reads = <String>[];

  /// Overlay fixtures for [locale]: catalog -> JSON object.
  factory FixtureBundle.locale(String locale, Map<String, Object> catalogs) =>
      FixtureBundle({
        for (final e in catalogs.entries)
          CatalogOverlay.assetPath(e.key, locale): e.value,
      });

  @override
  Future<ByteData> load(String key) async {
    reads.add(key);
    final s = _files[key];
    if (s == null) throw FlutterError('Unable to load asset: "$key".');
    return ByteData.sublistView(utf8.encode(s));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    reads.add(key);
    final s = _files[key];
    if (s == null) throw FlutterError('Unable to load asset: "$key".');
    return s;
  }
}

/// Russian strings of realistic length for the screens' layout tests.
const ruExercises = {
  'exercises': {
    'bench-press': {
      'name': 'Жим штанги лёжа на горизонтальной скамье',
      'steps': [
        'Глаза под грифом. Сведите и опустите лопатки, стопы прочно стоят на полу.',
        'Возьмитесь так, чтобы в нижней точке предплечья были вертикальны.',
        'Подконтрольно опустите гриф к низу груди, коснитесь и выжмите вверх и немного назад.',
        'Напрягите корпус и задержите дыхание на каждое повторение. Ягодицы остаются на скамье.',
      ],
      'mistakes': [
        'Отбив грифа от груди',
        'Локти разведены на 90°: нагрузка на плечевые суставы',
        'Таз отрывается от скамьи',
      ],
      'aliases': ['Жим лёжа', 'Жим штанги'],
    },
  },
  'muscles': {
    'Chest': 'Грудные мышцы',
    'Front delts': 'Передние дельтовидные',
    'Triceps': 'Трицепс',
  },
  'patterns': {'Horizontal push': 'Горизонтальный жим'},
};

const ruFoods = {
  'foods': {
    'chicken_breast': {'name': 'Куриная грудка, приготовленная'},
  },
  'portions': {'1 breast': '1 грудка', '1 bowl': '1 миска'},
};

const ruPrograms = {
  'upper-lower-4': {
    'name': 'Верх / низ 4×',
    'author': 'Шаблон FITRIX',
    'summary':
        'Для тех, кто тренируется около года и хочет нагружать каждую мышцу '
            'дважды в неделю: сначала тяжёлые базовые упражнения, затем '
            'умеренные вспомогательные.',
    'progressionRules': [
      'Двойная прогрессия: дойдите до верхней границы повторений во всех '
          'подходах, затем добавьте 2,5 кг на верх или 5 кг на низ.',
      'Разгрузка на 7-й неделе: оставьте те же упражнения, но сделайте '
          'примерно половину обычных подходов, чтобы усталость спала перед '
          'последним блоком.',
      'Наращивайте объём: с 1-й по 6-ю неделю добавляйте подходы сами, '
          'примерно с 10 до 16 на мышцу в неделю.',
    ],
    'sessions': ['Верх тела 1', 'Низ тела 1', 'Верх тела 2', 'Низ тела 2'],
  },
};

const ruWorkoutCatalog = {
  'templates': {
    'gym-legs': {'name': 'Ноги', 'focus': 'Низ тела'},
  },
  'exerciseNames': {
    'Bench press': 'Жим лёжа',
    'Barbell row': 'Тяга штанги в наклоне',
    'Overhead press': 'Жим штанги стоя',
    'Lat pulldown': 'Тяга верхнего блока',
    'Triceps pushdown': 'Разгибания рук на трицепс на блоке',
    'Back squat': 'Приседания со штангой',
    'Romanian deadlift': 'Румынская становая тяга',
    'Deadlift': 'Становая тяга',
  },
};
