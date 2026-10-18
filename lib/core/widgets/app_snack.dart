import 'package:flutter/material.dart';

/// Shows [message] in a snack bar, replacing any one already on screen.
void showAppSnack(
  BuildContext context,
  String message, {
  SnackBarAction? action,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action));
}
