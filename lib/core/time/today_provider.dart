import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitrix/core/time/day_key.dart';

/// The clock the app reads "now" from. Tests override it.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// The current local calendar day (date only). Day-scoped state watches it
/// so it rebuilds when the day changes. It is kept current by [DayRollover],
/// which the app mounts above the router.
final todayProvider =
    StateProvider<DateTime>((ref) => dayOf(ref.read(clockProvider)()));

/// Updates [todayProvider] when the app resumes on a new day and at local
/// midnight while it is open. The timer lives in this widget, so it is
/// cancelled when the widget goes away.
class DayRollover extends ConsumerStatefulWidget {
  final Widget child;
  const DayRollover({super.key, required this.child});

  @override
  ConsumerState<DayRollover> createState() => _DayRolloverState();
}

class _DayRolloverState extends ConsumerState<DayRollover>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  void _refresh() {
    final now = ref.read(clockProvider)();
    final day = dayOf(now);
    final notifier = ref.read(todayProvider.notifier);
    if (notifier.state != day) notifier.state = day;
    _timer?.cancel();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _timer = Timer(midnight.difference(now), _refresh);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
