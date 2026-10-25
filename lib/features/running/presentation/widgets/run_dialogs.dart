import 'package:flutter/material.dart';

import 'package:fitrix/features/running/data/activity_kind.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Asks before a recording of [kind] is thrown away. True when confirmed.
Future<bool> confirmDiscardRun(BuildContext context,
    [ActivityKind kind = ActivityKind.run]) async {
  final l10n = AppLocalizations.of(context);
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(switch (kind) {
            ActivityKind.run => l10n.runDiscardTitle,
            ActivityKind.ride => l10n.rideDiscardTitle,
            ActivityKind.ski => l10n.skiDiscardTitle,
          }),
          content: Text(l10n.runDiscardBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              key: const ValueKey('run-discard-confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.runDiscardAction),
            ),
          ],
        ),
      ) ??
      false;
}

/// Asks before a saved activity of [kind] is deleted. True when confirmed.
Future<bool> confirmDeleteRun(BuildContext context,
    [ActivityKind kind = ActivityKind.run]) async {
  final l10n = AppLocalizations.of(context);
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(switch (kind) {
            ActivityKind.run => l10n.runDeleteTitle,
            ActivityKind.ride => l10n.rideDeleteTitle,
            ActivityKind.ski => l10n.skiDeleteTitle,
          }),
          content: Text(kind == ActivityKind.ski
              ? l10n.skiDeleteBody
              : l10n.runDeleteBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              key: const ValueKey('run-delete-confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.runDeleteAction),
            ),
          ],
        ),
      ) ??
      false;
}

/// Another activity ([kind]) is unfinished: Resume it (true) or discard it
/// and start [next] (false). Null when dismissed.
Future<bool?> askUnfinishedRun(BuildContext context, String next,
    [ActivityKind kind = ActivityKind.run]) {
  final l10n = AppLocalizations.of(context);
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(switch (kind) {
        ActivityKind.run => l10n.runUnfinishedTitle,
        ActivityKind.ride => l10n.rideUnfinishedTitle,
        ActivityKind.ski => l10n.skiUnfinishedTitle,
      }),
      content: Text(kind == ActivityKind.ski
          ? l10n.skiUnfinishedBody(next)
          : l10n.runUnfinishedBody(next)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.gymDiscardAndStart),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.runResume),
        ),
      ],
    ),
  );
}
