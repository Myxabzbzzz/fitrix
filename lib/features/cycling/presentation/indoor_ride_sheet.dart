import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/time/day_key.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/features/plan/data/week_plan.dart' show sameDay;
import 'package:fitrix/features/football/presentation/match_log_sheet.dart'
    show LogPill, LogStepper;
import 'package:fitrix/features/running/data/run_store.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/widgets/live_log_rpe_sheet.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Template id of an indoor ride logged without a plan.
const indoorRideTemplateId = 'indoor_ride';

const _defaultMinutes = 45;
const _maxMinutes = 600;
const _noteLimit = 500;
const _maxKm = 1000.0;
const _maxPower = 2000;

/// The indoor ride log: a trainer ride written down after it is over.
/// With [editId] (a workout id) it edits that ride instead, and offers to
/// delete it. [template] ties the ride to its plan.
Future<void> showIndoorRideSheet(
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
    builder: (_) => _IndoorRideSheet(template: template, editId: editId),
  );
}

class _IndoorRideSheet extends ConsumerStatefulWidget {
  const _IndoorRideSheet({this.template, this.editId});

  final WorkoutTemplate? template;
  final String? editId;

  @override
  ConsumerState<_IndoorRideSheet> createState() => _IndoorRideSheetState();
}

class _IndoorRideSheetState extends ConsumerState<_IndoorRideSheet> {
  CompletedWorkout? _original;
  RunDetails? _originalDetails;

  late DateTime _day;
  int _minutes = _defaultMinutes;
  int? _rpe;
  final _km = TextEditingController();
  final _power = TextEditingController();
  final _note = TextEditingController();

  bool get _editing => _original != null && _originalDetails != null;

  @override
  void initState() {
    super.initState();
    _day = dayOf(ref.read(clockProvider)());
    final id = widget.editId;
    if (id != null) {
      _original =
          ref.read(workoutHistoryProvider).where((w) => w.id == id).firstOrNull;
      _originalDetails = ref.read(runsProvider)[id];
    }
    final o = _original, d = _originalDetails;
    if (o != null && d != null) {
      _day = dayOf(o.finishedAt.toLocal());
      _minutes = d.moving.inMinutes.clamp(5, _maxMinutes);
      _rpe = o.sessionRpe ?? d.rpe;
      if (d.meters > 0) _km.text = _formatKm(d.meters / 1000);
      if (d.avgPowerW != null) _power.text = '${d.avgPowerW}';
      _note.text = d.note ?? '';
    }
  }

  @override
  void dispose() {
    _km.dispose();
    _power.dispose();
    _note.dispose();
    super.dispose();
  }

  static String _formatKm(double km) =>
      km == km.roundToDouble() ? '${km.round()}' : '$km';

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

  /// The entered distance in metres; 0 when empty or not a number.
  double _meters() {
    final km = double.tryParse(_km.text.trim().replaceAll(',', '.'));
    if (km == null || km <= 0) return 0;
    return (km > _maxKm ? _maxKm : km) * 1000;
  }

  int? _watts() {
    final w = int.tryParse(_power.text.trim());
    if (w == null || w <= 0) return null;
    return w > _maxPower ? _maxPower : w;
  }

  String _name(CompletedWorkout? original) =>
      widget.template?.name ??
      original?.name ??
      AppLocalizations.of(context).indoorRideName;

  void _save() {
    final now = ref.read(clockProvider)();
    final history = ref.read(workoutHistoryProvider.notifier);
    final runs = ref.read(runsProvider.notifier);
    final original = _original;
    final note = _note.text.trim();

    final DateTime finishedAt;
    if (original != null && sameDay(original.finishedAt.toLocal(), _day)) {
      finishedAt = original.finishedAt;
    } else if (sameDay(_day, now)) {
      finishedAt = now;
    } else {
      finishedAt = DateTime(_day.year, _day.month, _day.day, 20);
    }
    final templateId =
        original?.templateId ?? widget.template?.id ?? indoorRideTemplateId;
    final length = Duration(minutes: _minutes);
    final startedAt = finishedAt.subtract(length);
    final details = RunDetails(
      startedAt: startedAt,
      moving: length,
      elapsed: length,
      pauses: 0,
      meters: _meters(),
      splits: const [],
      route: const [],
      rpe: _rpe,
      templateId: templateId,
      kind: ActivityKind.ride,
      indoor: true,
      avgPowerW: _watts(),
      note: note.isEmpty ? null : note,
    );

    if (original != null &&
        _originalDetails != null &&
        original.finishedAt == finishedAt &&
        original.name == _name(original) &&
        original.duration.inMinutes == _minutes) {
      // Same moment and length: the workout stays, only the details change.
      runs.put(original.id, details);
      final rpe = _rpe;
      if (rpe != null && rpe != original.sessionRpe) {
        history.setRpe(original.id, rpe);
      }
    } else {
      final id = const Uuid().v4();
      // The Health writer reads the distance when the workout is added.
      runs.put(id, details);
      // An edit replaces the session: only a new log goes to Health.
      history.add(
          toHealth: original == null,
          CompletedWorkout(
            id: id,
            templateId: templateId,
            name: _name(original),
            sport: Sport.cycling,
            startedAt: startedAt,
            finishedAt: finishedAt,
            exercises: const [],
            sessionRpe: _rpe,
          ));
      if (original != null) {
        history.remove(original.id);
        runs.remove(original.id);
      }
    }
    Navigator.pop(context);
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
            key: const ValueKey('ride-delete-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.footballDeleteAction),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final id = _original!.id;
    ref.read(workoutHistoryProvider.notifier).remove(id);
    ref.read(runsProvider.notifier).remove(id);
    Navigator.pop(context);
  }

  InputDecoration _decoration(AppPalette palette) => InputDecoration(
        counterText: '',
        filled: true,
        fillColor: palette.tile,
        border: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final today = dayOf(ref.read(clockProvider)());
    final dateText = _day == today
        ? l10n.gymToday
        : DateFormat.MMMEd(l10n.localeName).format(_day);
    final fieldStyle = AppText.body14.copyWith(color: palette.textPrimary);

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
                _editing ? l10n.rideEditTitle : l10n.rideLogTitle,
                style: AppText.headingM.copyWith(color: palette.textPrimary),
              ),
              label(l10n.footballDate),
              LogPill(
                key: const ValueKey('ride-date'),
                label: dateText,
                selected: false,
                icon: Icons.calendar_today_outlined,
                onTap: _pickDate,
              ),
              label(l10n.footballMinutes),
              LogStepper(
                keyPrefix: 'ride-minutes',
                value: _minutes,
                step: 5,
                min: 5,
                max: _maxMinutes,
                onChanged: (v) => setState(() => _minutes = v),
              ),
              label(l10n.rideLogDistance),
              TextField(
                key: const ValueKey('ride-km'),
                controller: _km,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  LengthLimitingTextInputFormatter(7),
                ],
                style: fieldStyle,
                decoration: _decoration(palette),
              ),
              label(l10n.rideLogPower),
              TextField(
                key: const ValueKey('ride-power'),
                controller: _power,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                style: fieldStyle,
                decoration: _decoration(palette),
              ),
              label(l10n.runRpeTitle),
              RpeScale(
                keyPrefix: 'ride-rpe',
                selected: _rpe,
                onPick: (n) => setState(() => _rpe = n),
              ),
              label(l10n.rideNote),
              TextField(
                key: const ValueKey('ride-note'),
                controller: _note,
                maxLength: _noteLimit,
                maxLines: 3,
                minLines: 1,
                style: fieldStyle,
                decoration: _decoration(palette),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                key: const ValueKey('ride-save'),
                label: l10n.footballSave,
                size: AppButtonSize.large,
                expand: true,
                onPressed: _save,
              ),
              if (_editing) ...[
                const SizedBox(height: AppSpacing.xs),
                AppButton(
                  key: const ValueKey('ride-delete'),
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
