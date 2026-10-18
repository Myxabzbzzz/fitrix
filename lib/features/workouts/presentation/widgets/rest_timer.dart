import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Default rest between sets when the exercise has none of its own.
const int kDefaultRestSeconds = 120;

/// Countdown between sets. It keeps an end time from [clock], so it stays
/// right while nothing is listening (sheet collapsed, keyboard open, app in
/// the background). The rest bar only repaints it, calling [tick] each frame.
class RestTimerController extends ChangeNotifier {
  /// [clock] defaults to [DateTime.now]; tests inject their own.
  RestTimerController({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  DateTime? _end;
  Duration _total = Duration.zero;
  String? _next;

  /// Time left; zero when no rest is running.
  Duration get remaining {
    final end = _end;
    if (end == null) return Duration.zero;
    final left = end.difference(_clock());
    return left > Duration.zero ? left : Duration.zero;
  }

  /// Length of the current rest (grows with [add]), for the progress bar.
  Duration get total => _total;

  /// Label of what comes next, e.g. "Set 3 · 72.5 × 8".
  String? get next => _next;

  bool get active => remaining > Duration.zero;

  /// 0 (just started) to 1 (done).
  double get progress => _total == Duration.zero
      ? 0
      : (1 - remaining.inMicroseconds / _total.inMicroseconds).clamp(0.0, 1.0);

  void start(Duration duration, {String? next}) {
    _total = duration;
    _end = _clock().add(duration);
    _next = next;
    notifyListeners();
  }

  /// Adds (or with a negative [delta] removes) time; the rest ends when
  /// nothing is left.
  void add(Duration delta) {
    if (!active) return;
    _end = _end!.add(delta);
    _total += delta;
    if (!active) _finish();
    notifyListeners();
  }

  void skip() {
    if (_end == null) return;
    _finish();
    notifyListeners();
  }

  /// Called every frame by the rest bar: repaints and ends an expired rest.
  void tick() {
    if (_end == null) return;
    if (!active) _finish();
    notifyListeners();
  }

  void _finish() {
    _end = null;
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
  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => widget.controller.tick())..start();
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
