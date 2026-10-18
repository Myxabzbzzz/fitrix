import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// True while About me has unsaved edits; read by the route's exit guard.
final aboutMeDirtyProvider = StateProvider<bool>((ref) => false);

/// The "Discard changes?" dialog; true when the user chose to discard.
Future<bool> confirmDiscardChanges(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final discard = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.aboutMeDiscardTitle),
      content: Text(l10n.aboutMeDiscardBody),
      actions: [
        TextButton(
          key: const Key('about-keep-editing'),
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.aboutMeKeepEditing),
        ),
        TextButton(
          key: const Key('about-discard'),
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
              foregroundColor: AppPalette.of(context).danger),
          child: Text(l10n.aboutMeDiscard),
        ),
      ],
    ),
  );
  return discard == true;
}

/// [GoRoute.onExit] for About me: asks before unsaved edits are dropped.
Future<bool> aboutMeOnExit(BuildContext context, GoRouterState state) async {
  final dirty =
      ProviderScope.containerOf(context).read(aboutMeDirtyProvider.notifier);
  if (!dirty.state) return true;
  final discard = await confirmDiscardChanges(context);
  if (discard) dirty.state = false;
  return discard;
}
