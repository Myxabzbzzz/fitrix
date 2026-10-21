import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/time/day_key.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/features/football/data/match_log.dart';
import 'package:fitrix/features/football/data/match_store.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/widgets/live_log_rpe_sheet.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Template id of a football log made without a plan.
const footballLogTemplateId = 'football_log';

const _defaultMinutes = 50;
const _defaultFormat = '7x7';
const _maxMinutes = 300;
const _noteLimit = 500;

/// The football log: a game or a training, written down after it is over.
/// With [editId] (a workout id) it edits that entry instead, and offers to
/// delete it. [template] names a training and ties it to its plan.
Future<void> showMatchLogSheet(
  BuildContext context,
  WidgetRef ref, {
  WorkoutTemplate? template,
  String? editId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppPalette.of(context).background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => _MatchLogSheet(template: template, editId: editId),
  );
}

class _MatchLogSheet extends ConsumerStatefulWidget {
  const _MatchLogSheet({this.template, this.editId});

  final WorkoutTemplate? template;
  final String? editId;

  @override
  ConsumerState<_MatchLogSheet> createState() => _MatchLogSheetState();
}

class _MatchLogSheetState extends ConsumerState<_MatchLogSheet> {
  CompletedWorkout? _original;
  MatchLog? _originalLog;

  var _type = FootballType.match;
  late DateTime _day;
  String _format = _defaultFormat;
  int _minutes = _defaultMinutes;
  String? _position;
  int? _rpe;
  int _for = 0, _against = 0, _goals = 0, _assists = 0;

  /// The result is optional: it stays unset (saved as none) until either
  /// score stepper is touched.
  bool _scored = false;
  final _note = TextEditingController();

  bool get _editing => _original != null && _originalLog != null;
  bool get _isMatch => _type == FootballType.match;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider)();
    _day = dayOf(now);
    final id = widget.editId;
    if (id != null) {
      _original =
          ref.read(workoutHistoryProvider).where((w) => w.id == id).firstOrNull;
      _originalLog = ref.read(matchesProvider)[id];
    }
    final log = _originalLog;
    if (_original != null && log != null) {
      _type = log.type;
      _day = dayOf(_original!.finishedAt.toLocal());
      _format = log.format ?? _defaultFormat;
      _minutes = log.minutes;
      _position = log.position;
      _rpe = _original!.sessionRpe ?? log.rpe;
      _scored = log.goalsFor != null || log.goalsAgainst != null;
      _for = log.goalsFor ?? 0;
      _against = log.goalsAgainst ?? 0;
      _goals = log.goals ?? 0;
      _assists = log.assists ?? 0;
      _note.text = log.note ?? '';
    } else {
      _position = _lastPosition();
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// The position of the newest log that has one.
  String? _lastPosition() {
    final logs = ref.read(matchesProvider).values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    for (final l in logs) {
      if (l.position != null) return l.position;
    }
    return null;
  }

  static DateTime _minDate(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

  Future<void> _pickDate() async {
    final today = dayOf(ref.read(clockProvider)());
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate:
          _minDate(DateTime(today.year - 1, today.month, today.day), _day),
      lastDate: today,
    );
    if (picked != null) setState(() => _day = dayOf(picked));
  }

  void _save() {
    final now = ref.read(clockProvider)();
    final history = ref.read(workoutHistoryProvider.notifier);
    final matches = ref.read(matchesProvider.notifier);
    final match = _isMatch;
    final note = _note.text.trim();
    final original = _original;

    final DateTime finishedAt;
    if (original != null && sameDay(original.finishedAt.toLocal(), _day)) {
      finishedAt = original.finishedAt;
    } else if (sameDay(_day, now)) {
      finishedAt = now;
    } else {
      finishedAt = DateTime(_day.year, _day.month, _day.day, 20);
    }
    final templateId = _originalLog?.templateId ??
        widget.template?.id ??
        footballLogTemplateId;
    final log = MatchLog(
      type: _type,
      date: finishedAt,
      format: match ? _format : null,
      minutes: _minutes,
      position: _position,
      rpe: _rpe,
      goalsFor: match && _scored ? _for : null,
      goalsAgainst: match && _scored ? _against : null,
      goals: match ? _goals : null,
      assists: match ? _assists : null,
      note: match && note.isNotEmpty ? note : null,
      templateId: templateId,
    );

    if (original != null &&
        _originalLog != null &&
        original.finishedAt == finishedAt &&
        original.name == _name(original) &&
        original.duration.inMinutes == _minutes) {
      // Same moment and length: the workout stays, only the log changes.
      matches.put(original.id, log);
      final rpe = _rpe;
      if (rpe != null && rpe != original.sessionRpe) {
        history.setRpe(original.id, rpe);
      }
    } else {
      final id = const Uuid().v4();
      history.add(CompletedWorkout(
        id: id,
        templateId: templateId,
        name: _name(original),
        sport: Sport.football,
        startedAt: finishedAt.subtract(Duration(minutes: _minutes)),
        finishedAt: finishedAt,
        exercises: const [],
        sessionRpe: _rpe,
      ));
      matches.put(id, log);
      if (original != null) {
        history.remove(original.id);
        matches.remove(original.id);
      }
    }
    Navigator.pop(context);
  }

  String _name(CompletedWorkout? original) {
    if (_isMatch) return 'Football ${formatLabel(_format)}';
    final fromPlan = widget.template?.name;
    if (fromPlan != null) return fromPlan;
    if (original != null &&
        _originalLog?.type == FootballType.training &&
        original.templateId != footballLogTemplateId) {
      return original.name;
    }
    return 'Football training';
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.footballDeleteTitle),
        content: Text(l10n.footballDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const ValueKey('fb-delete-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.footballDeleteAction),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final id = _original!.id;
    ref.read(workoutHistoryProvider.notifier).remove(id);
    ref.read(matchesProvider.notifier).remove(id);
    Navigator.pop(context);
  }

  String _positionLabel(AppLocalizations l10n, String p) => switch (p) {
        'GK' => l10n.footballPosGK,
        'CB' => l10n.footballPosCB,
        'FB' => l10n.footballPosFB,
        'CM' => l10n.footballPosCM,
        'WM' => l10n.footballPosWM,
        _ => l10n.footballPosST,
      };

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final today = dayOf(ref.read(clockProvider)());
    final dateText = _day == today
        ? l10n.gymToday
        : DateFormat.MMMEd(l10n.localeName).format(_day);

    Widget label(String text) => Padding(
          padding:
              const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
          child: Text(text.toUpperCase(),
              style:
                  AppText.captionStrong.copyWith(color: palette.textSecondary)),
        );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _editing ? l10n.footballEditTitle : l10n.footballLogTitle,
                style: AppText.headingM.copyWith(color: palette.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _Pill(
                      key: const ValueKey('fb-type-match'),
                      label: l10n.footballTypeMatch,
                      selected: _isMatch,
                      onTap: () => setState(() => _type = FootballType.match),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _Pill(
                      key: const ValueKey('fb-type-training'),
                      label: l10n.footballTypeTraining,
                      selected: !_isMatch,
                      onTap: () =>
                          setState(() => _type = FootballType.training),
                    ),
                  ),
                ],
              ),
              label(l10n.footballDate),
              _Pill(
                key: const ValueKey('fb-date'),
                label: dateText,
                selected: false,
                icon: Icons.calendar_today_outlined,
                onTap: _pickDate,
              ),
              label(l10n.footballMinutes),
              _Stepper(
                keyPrefix: 'fb-minutes',
                value: _minutes,
                step: 5,
                min: 5,
                max: _maxMinutes,
                onChanged: (v) => setState(() => _minutes = v),
              ),
              label(l10n.footballPosition),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final p in footballPositions)
                    _Pill(
                      key: ValueKey('fb-position-$p'),
                      label: _positionLabel(l10n, p),
                      selected: _position == p,
                      onTap: () =>
                          setState(() => _position = _position == p ? null : p),
                    ),
                ],
              ),
              if (_isMatch) ...[
                label(l10n.footballFormat),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final f in footballFormats)
                      _Pill(
                        key: ValueKey('fb-format-$f'),
                        label: formatLabel(f),
                        selected: _format == f,
                        onTap: () => setState(() => _format = f),
                      ),
                  ],
                ),
                label(l10n.footballResult),
                Row(
                  children: [
                    Expanded(
                      child: _Stepper(
                        keyPrefix: 'fb-for',
                        caption: l10n.footballScoreFor,
                        value: _for,
                        unset: !_scored,
                        onChanged: (v) => setState(() {
                          _scored = true;
                          _for = v;
                        }),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _Stepper(
                        keyPrefix: 'fb-against',
                        caption: l10n.footballScoreAgainst,
                        value: _against,
                        unset: !_scored,
                        onChanged: (v) => setState(() {
                          _scored = true;
                          _against = v;
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _Stepper(
                        keyPrefix: 'fb-goals',
                        caption: l10n.footballGoals,
                        value: _goals,
                        onChanged: (v) => setState(() => _goals = v),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _Stepper(
                        keyPrefix: 'fb-assists',
                        caption: l10n.footballAssists,
                        value: _assists,
                        onChanged: (v) => setState(() => _assists = v),
                      ),
                    ),
                  ],
                ),
              ],
              label(l10n.runRpeTitle),
              RpeScale(
                keyPrefix: 'fb-rpe',
                selected: _rpe,
                onPick: (n) => setState(() => _rpe = n),
              ),
              if (_isMatch) ...[
                label(l10n.footballNote),
                TextField(
                  key: const ValueKey('fb-note'),
                  controller: _note,
                  maxLength: _noteLimit,
                  maxLines: 3,
                  minLines: 1,
                  style: AppText.body14.copyWith(color: palette.textPrimary),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: palette.tile,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.smAll,
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AppButton(
                key: const ValueKey('fb-save'),
                label: l10n.footballSave,
                size: AppButtonSize.large,
                expand: true,
                onPressed: _save,
              ),
              if (_editing) ...[
                const SizedBox(height: AppSpacing.xs),
                AppButton(
                  key: const ValueKey('fb-delete'),
                  label: l10n.footballDelete,
                  style: AppButtonStyle.secondary,
                  size: AppButtonSize.large,
                  expand: true,
                  onPressed: _delete,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final fg = selected ? palette.onAccent : palette.textPrimary;
    return Material(
      color: selected ? palette.accent : palette.tile,
      borderRadius: AppRadius.smAll,
      child: InkWell(
        borderRadius: AppRadius.smAll,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: fg),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: AppText.bodyStrong.copyWith(color: fg)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A whole number with minus and plus buttons; keys `<prefix>-minus`,
/// `<prefix>-plus` and `<prefix>-value`. While [unset] it shows a dash and
/// either button sets it (minus to [value]).
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.keyPrefix,
    required this.value,
    required this.onChanged,
    this.caption,
    this.step = 1,
    this.min = 0,
    this.max = 99,
    this.unset = false,
  });

  final String keyPrefix;
  final String? caption;
  final int value, step, min, max;
  final bool unset;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    Widget button(String name, IconData icon, int next, bool enabled) =>
        Material(
          color: palette.tile,
          borderRadius: AppRadius.smAll,
          child: InkWell(
            key: ValueKey('$keyPrefix-$name'),
            borderRadius: AppRadius.smAll,
            onTap: enabled ? () => onChanged(next) : null,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon,
                  size: 20,
                  color: enabled
                      ? palette.textPrimary
                      : palette.textSecondary.withValues(alpha: 0.4)),
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (caption != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
            child: Text(caption!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(color: palette.textSecondary)),
          ),
        Row(
          children: [
            unset
                ? button('minus', Icons.remove, value, true)
                : button(
                    'minus', Icons.remove, value - step, value - step >= min),
            Expanded(
              child: Text(
                unset ? '–' : '$value',
                key: ValueKey('$keyPrefix-value'),
                textAlign: TextAlign.center,
                style: AppText.headingM.copyWith(
                  color: palette.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            button('plus', Icons.add, value + step, value + step <= max),
          ],
        ),
      ],
    );
  }
}
