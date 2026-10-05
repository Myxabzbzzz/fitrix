import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/widgets/active_workout_sheet.dart';

/// App shell after onboarding: the 5-tab bar from the design
/// (Discover · Shop · Home · Felix · Profile) plus the active workout sheet
/// that floats above every tab.
class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  void _onTap(int index) {
    // Tapping the current tab returns to its root (e.g. Home from My workouts).
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActiveWorkout = ref.watch(
      activeWorkoutProvider.select((w) => w != null),
    );

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            bottom: hasActiveWorkout ? ActiveWorkoutSheet.collapsedHeight : 0,
            child: navigationShell,
          ),
          const Positioned.fill(child: ActiveWorkoutSheet()),
        ],
      ),
      bottomNavigationBar: _TabBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _TabBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    Widget icon(int index, IconData outlined, IconData filled, String label) {
      final selected = index == currentIndex;
      return Icon(
        selected ? filled : outlined,
        size: 26,
        color: palette.tabInactive,
        semanticLabel: label,
      );
    }

    final felixSelected = currentIndex == 3;
    final items = <Widget>[
      icon(0, Icons.explore_outlined, Icons.explore, 'Discover'),
      icon(1, Icons.shopping_cart_outlined, Icons.shopping_cart, 'Shop'),
      icon(2, Icons.home_outlined, Icons.home, 'Home'),
      Text(
        'FI',
        semanticsLabel: 'Felix',
        style: TextStyle(
          fontSize: 20,
          fontWeight: felixSelected ? FontWeight.w800 : FontWeight.w600,
          color: palette.accent,
        ),
      ),
      icon(4, Icons.person_outline, Icons.person, 'Profile'),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.tabBar,
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 1, offset: Offset(0, -0.5)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkResponse(
                    onTap: () => onTap(i),
                    child: Center(child: items[i]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
