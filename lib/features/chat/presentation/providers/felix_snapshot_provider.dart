import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/chat/data/felix_snapshot.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/checkin/presentation/providers/checkin_provider.dart';
import 'package:fitrix/features/football/data/match_store.dart';
import 'package:fitrix/features/health/data/health_import_store.dart';
import 'package:fitrix/features/health/presentation/providers/health_providers.dart';
import 'package:fitrix/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fitrix/features/plan/presentation/providers/week_plan_provider.dart';
import 'package:fitrix/features/progress/presentation/providers/progress_providers.dart';
import 'package:fitrix/features/running/data/run_store.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';

/// What Felix knows for a topic right now, sent as the chat `context`.
final felixSnapshotProvider =
    Provider.family<FelixSnapshot, AssistantTopic>((ref, topic) {
  final checkIn = ref.watch(todayCheckInProvider);
  return buildFelixSnapshot(
    topic: topic,
    today: ref.watch(todayProvider),
    plan: ref.watch(weekPlanProvider),
    history: ref.watch(workoutHistoryProvider),
    readiness: ref.watch(todayReadinessProvider),
    sleepHours: checkIn == null ? null : checkIn.sleep.inMinutes / 60,
    hardDays7: ref.watch(hardDaysProvider),
    entries: ref.watch(todayEntriesProvider),
    waterMl: ref.watch(todayWaterProvider),
    targets: ref.watch(targetsProvider),
    weighIns: ref.watch(bodyWeightProvider),
    runs: ref.watch(runsProvider),
    matches: ref.watch(matchesProvider),
    health: topic == AssistantTopic.recovery
        ? ref.watch(healthTodayProvider)
        : null,
    imports: ref.watch(healthImportsProvider),
  );
});
