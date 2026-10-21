import 'package:flutter/material.dart';

import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Asks before a recording is thrown away. True when confirmed.
Future<bool> confirmDiscardRun(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.runDiscardTitle),
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

/// Asks before a saved run is deleted. True when confirmed.
Future<bool> confirmDeleteRun(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.runDeleteTitle),
          content: Text(l10n.runDeleteBody),
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

/// Another run is unfinished: Resume it (true) or discard it and start
/// [next] (false). Null when dismissed.
Future<bool?> askUnfinishedRun(BuildContext context, String next) {
  final l10n = AppLocalizations.of(context);
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.runUnfinishedTitle),
      content: Text(l10n.runUnfinishedBody(next)),
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
