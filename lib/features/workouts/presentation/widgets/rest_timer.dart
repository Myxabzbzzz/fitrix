import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Default rest between sets when the exercise has none of its own.
const int kDefaultRestSeconds = 120;

/// Countdown between sets. It doesn't run by itself: whoever shows it feeds
/// it elapsed time with [tick] (the rest bar does, from a frame ticker), so
/// tests can advance it with `tester.pump(Duration)`.
class RestTimerController extends ChangeNotifier {
  Duration _total = Duration.zero;
  Duration _remaining = Duration.zero;
  String? _next;

  /// Time left; zero when no rest is running.
  Duration get remaining => _remaining;

  /// Length of the current rest (grows with [add]), for the progress bar.
  Duration get total => _total;

  /// Label of what comes next, e.g. "Set 3 · 72.5 × 8".
  String? get next => _next;

  bool get active => _remaining > Duration.zero;

  /// 0 (just started) to 1 (done).
  double get progress => _total == Duration.zero
      ? 0
      : (1 - _remaining.inMicroseconds / _total.inMicroseconds).clamp(0.0, 1.0);

  void start(Duration duration, {String? next}) {
    _total = duration;
    _remaining = duration;
    _next = next;
    notifyListeners();
  }

  /// Adds (or with a negative [delta] removes) time; the rest ends when
  /// nothing is left.
  void add(Duration delta) {
    if (!active) return;
    _remaining += delta;
    _total += delta;
    if (_remaining <= Duration.zero) _end();
    notifyListeners();
  }

  void skip() {
    if (!active) return;
    _end();
    notifyListeners();
  }

  /// Counts [elapsed] down.
  void tick(Duration elapsed) {
    if (!active) return;
    _remaining -= elapsed;
    if (_remaining <= Duration.zero) _end();
    notifyListeners();
  }

  void _end() {
    _remaining = Duration.zero;
    _total = Duration.zero;
    _next = null;
  }
}

/// One timer for the active workout.
final restTimerProvider = Provider<RestTimerController>((ref) {
  final controller = RestTimerController();
  ref.onDispose(controller.dispose);
  return controller;
});

/// "2:05" for a duration, rounding up to whole seconds.
String formatClock(Duration d) {
  final seconds = (d.inMilliseconds + 999) ~/ 1000;
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '${seconds ~/ 60}:$s';
}

/// The bar floating above the bottom buttons while a rest runs:
/// time left, what's next, −15s / +15s / Skip and a progress line.
class RestBar extends StatelessWidget {
  final RestTimerController controller;

  const RestBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => controller.active
          ? _RestBarBody(controller: controller)
          : const SizedBox.shrink(),
    );
  }
}

class _RestBarBody extends StatefulWidget {
  final RestTimerController controller;

  const _RestBarBody({required this.controller});

  @override
  State<_RestBarBody> createState() => _RestBarBodyState();
}

class _RestBarBodyState extends State<_RestBarBody>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final delta = elapsed - _last;
      _last = elapsed;
      widget.controller.tick(delta);
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final c = widget.controller;
    final onDark = palette.onPillSelected;

    Widget pill(String label, VoidCallback onTap, {bool primary = false}) =>
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: const BoxConstraints(minHeight: 32),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primary ? palette.accent : onDark.withValues(alpha: 0.16),
              borderRadius: AppRadius.fullAll,
            ),
            child: Text(
              label,
              style: AppText.bodyStrong
                  .copyWith(color: primary ? palette.onAccent : onDark),
            ),
          ),
        );

    final next = c.next;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: palette.pillSelected,
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            [
              l10n.workoutRestLabel.toUpperCase(),
              if (next != null) l10n.workoutRestNext(next).toUpperCase(),
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.microStrong
                .copyWith(color: onDark.withValues(alpha: 0.7)),
          ),
          Row(
            children: [
              Text(
                formatClock(c.remaining),
                style: AppText.headingL.copyWith(
                  color: onDark,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      pill(l10n.workoutRestSub(15),
                          () => c.add(const Duration(seconds: -15))),
                      const SizedBox(width: AppSpacing.xs),
                      pill(l10n.workoutRestAdd(15),
                          () => c.add(const Duration(seconds: 15))),
                      const SizedBox(width: AppSpacing.xs),
                      pill(l10n.workoutRestSkip, c.skip, primary: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          ClipRRect(
            borderRadius: AppRadius.fullAll,
            child: SizedBox(
              height: 3,
              child: LinearProgressIndicator(
                value: 1 - c.progress,
                minHeight: 3,
                backgroundColor: onDark.withValues(alpha: 0.16),
                valueColor: AlwaysStoppedAnimation(palette.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
