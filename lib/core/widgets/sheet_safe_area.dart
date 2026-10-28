import 'package:flutter/widgets.dart';

/// Bottom-sheet content insets: clears the home indicator, and the keyboard
/// while it is up. Sheets open on the root navigator, below the tab bar's
/// own safe area, so they have to do this themselves.
class SheetSafeArea extends StatelessWidget {
  final Widget child;

  const SheetSafeArea({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      // With the keyboard up the bottom padding is already 0 (it is under
      // the keyboard), so the two never add up.
      child: SafeArea(top: false, child: child),
    );
  }
}
