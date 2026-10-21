import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/app_snack.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/running/presentation/run_format.dart';
import 'package:fitrix/features/running/presentation/run_recorder.dart';
import 'package:fitrix/features/running/presentation/widgets/run_dialogs.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// How long Finish has to be held.
const holdToFinish = Duration(seconds: 1);

/// Set from a push of the live run until the next frame, when the router's
/// configuration shows it.
bool _liveRunOpening = false;

/// Opens the live run, unless it is already on the stack or being opened:
/// a double tap (on the run bar, on Start run) never stacks a second one.
void openLiveRun(GoRouter router) {
  if (_liveRunOpening) return;
  final open = router.routerDelegate.currentConfiguration.matches
      .any((m) => m.matchedLocation == AppRouter.liveRun);
  if (open) return;
  _liveRunOpening = true;
  final binding = WidgetsBinding.instance;
  binding.addPostFrameCallback((_) => _liveRunOpening = false);
  binding.ensureVisualUpdate();
  router.push(AppRouter.liveRun);
}

/// The run being recorded: time, distance, pace, Pause/Resume and a
/// press-and-hold Finish. Leaving the screen does not stop the run.
class LiveRunScreen extends ConsumerStatefulWidget {
  const LiveRunScreen({super.key});

  @override
  ConsumerState<LiveRunScreen> createState() => _LiveRunScreenState();
}

class _LiveRunScreenState extends ConsumerState<LiveRunScreen> {
  Timer? _tick;

  /// Kept so the last numbers stay up while Finish is saving.
  RunSession? _last;

  /// Finish started (it runs once, however many times it is triggered).
  bool _finishing = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _close() {
    _leaving = true;
    final router = GoRouter.of(context);
    router.canPop() ? router.pop() : router.go(AppRouter.home);
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    final router = GoRouter.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      final workout = await ref.read(runRecorderProvider.notifier).finish();
      if (!mounted) return;
      _leaving = true;
      router.pushReplacement(
          AppRouter.runSummary(workout.id, justFinished: true));
    } catch (_) {
      if (!mounted) return;
      // The run is gone already (discarded elsewhere): nothing to finish.
      if (ref.read(runRecorderProvider) == null) {
        _close();
        return;
      }
      // Saving failed: the run keeps recording and Finish can be tried again.
      setState(() => _finishing = false);
      showAppSnack(context, l10n.runFinishFailed);
    }
  }

  Future<void> _discard() async {
    if (_finishing) return;
    if (!await confirmDiscardRun(context) || !mounted || _finishing) return;
    _finishing = true;
    await ref.read(runRecorderProvider.notifier).discard();
    if (mounted) _close();
  }

  void _togglePause(RunSession s) {
    final recorder = ref.read(runRecorderProvider.notifier);
    s.phase == RunPhase.running ? recorder.pause() : recorder.resume();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(runRecorderProvider) ?? _last;
    if (session == null) {
      if (!_leaving) {
        _leaving = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _close();
        });
      }
      return Scaffold(backgroundColor: palette.background);
    }
    _last = session;

    final now = ref.read(clockProvider)();
    final moving = session.track.movingTime(now);
    final meters = session.track.meters;
    final paused = session.phase == RunPhase.paused;
    final template = session.template;
    final title = template?.name ?? defaultRunName(l10n, session.startedAt);
    final hint = template?.exercises.map((e) => e.name).join(' · ');
    final locale = l10n.localeName;
    // Read on every build: the screen rebuilds each second.
    final recorder = ref.read(runRecorderProvider.notifier);
    final gps = recorder.gpsStatus();
    final preciseOff = recorder.preciseLocationOff;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: box.maxHeight - 2 * AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        key: const ValueKey('run-close'),
                        tooltip:
                            MaterialLocalizations.of(context).backButtonTooltip,
                        onPressed: _close,
                        icon: Icon(Icons.keyboard_arrow_down,
                            color: palette.textPrimary),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppText.headingS
                              .copyWith(color: palette.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  if (hint != null && hint.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xxs),
                      child: Text(
                        hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppText.body14
                            .copyWith(color: palette.textSecondary),
                      ),
                    ),
                  if (gps == GpsStatus.waiting || gps == GpsStatus.weak)
                    _GpsLine(
                      key: const ValueKey('run-gps'),
                      icon: gps == GpsStatus.waiting
                          ? Icons.gps_not_fixed
                          : Icons.gps_off,
                      text: gps == GpsStatus.waiting
                          ? l10n.runGpsWaiting
                          : l10n.runGpsWeak,
                    ),
                  if (preciseOff)
                    _GpsLine(
                      key: const ValueKey('run-gps-precise'),
                      icon: Icons.location_searching,
                      text: l10n.runGpsReduced,
                      warning: true,
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  _Stat(
                    label: paused ? l10n.runPausedLabel : l10n.runTime,
                    value: formatClock(moving),
                    size: 72,
                    valueKey: const ValueKey('run-time'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _Stat(
                    label: '${l10n.runDistance}, ${l10n.runUnitKm}',
                    value: formatKm(meters, locale),
                    size: 48,
                    valueKey: const ValueKey('run-distance'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          label: '${l10n.runPace}, ${l10n.runUnitPerKm}',
                          value: formatPace(currentPaceSecPerKm(session.track)),
                          size: 32,
                          valueKey: const ValueKey('run-pace'),
                        ),
                      ),
                      Expanded(
                        child: _Stat(
                          label: '${l10n.runAvgPace}, ${l10n.runUnitPerKm}',
                          value: formatPace(paceSecPerKm(meters, moving)),
                          size: 32,
                          valueKey: const ValueKey('run-avg-pace'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    key: const ValueKey('run-pause'),
                    label: paused ? l10n.runResume : l10n.runPause,
                    icon: paused ? Icons.play_arrow : Icons.pause,
                    size: AppButtonSize.large,
                    style: paused
                        ? AppButtonStyle.primary
                        : AppButtonStyle.secondary,
                    expand: true,
                    onPressed: _finishing ? null : () => _togglePause(session),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  HoldToFinish(
                    key: const ValueKey('run-finish'),
                    label: l10n.runHoldToFinish,
                    onDone: _finish,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextButton(
                    key: const ValueKey('run-discard'),
                    onPressed: _finishing ? null : _discard,
                    child: Text(l10n.runDiscardRun,
                        style: AppText.bodyStrong
                            .copyWith(color: palette.textSecondary)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small line about the GPS under the title.
class _GpsLine extends StatelessWidget {
  const _GpsLine({
    super.key,
    required this.icon,
    required this.text,
    this.warning = false,
  });

  final IconData icon;
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final color = warning ? palette.warning : palette.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xxs),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.size,
    required this.valueKey,
  });

  final String label, value;
  final double size;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Column(
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.caption.copyWith(color: palette.textSecondary),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            key: valueKey,
            style: AppText.displayLarge.copyWith(
              fontSize: size,
              color: palette.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

/// A button that fills while it is held and calls [onDone] once when it
/// has been held still for [holdToFinish]. Letting go earlier, moving more
/// than the touch slop or a scroll taking the drag resets it and does
/// nothing.
class HoldToFinish extends StatefulWidget {
  const HoldToFinish({super.key, required this.label, required this.onDone});

  final String label;
  final VoidCallback onDone;

  @override
  State<HoldToFinish> createState() => _HoldToFinishState();
}

class _HoldToFinishState extends State<HoldToFinish>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fill =
      AnimationController(vsync: this, duration: holdToFinish);

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  void _down(LongPressDownDetails _) => _fill.forward(from: 0);

  void _reset() => _fill.reset();

  void _done(LongPressStartDetails _) => widget.onDone();

  void _end(LongPressEndDetails _) => _reset();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Semantics(
      button: true,
      label: widget.label,
      onLongPress: widget.onDone,
      child: ExcludeSemantics(
        // A long press joins the gesture arena: a drag past the touch slop
        // (a scroll, cloth in a pocket) cancels it before it fires.
        child: RawGestureDetector(
          gestures: {
            LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(
                  duration: holdToFinish, debugOwner: this),
              (r) {
                r
                  ..onLongPressDown = _down
                  ..onLongPressCancel = _reset
                  ..onLongPressStart = _done
                  ..onLongPressEnd = _end;
              },
            ),
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 56,
              color: palette.buttonMuted,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _fill,
                      builder: (context, _) => Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _fill.value,
                          heightFactor: 1,
                          child: ColoredBox(color: palette.accent),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          AppText.headingS.copyWith(color: palette.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
