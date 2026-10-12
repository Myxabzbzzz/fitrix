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
      return Icon(
        index == currentIndex ? filled : outlined,
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
      Semantics(
        label: 'Felix',
        image: true,
        child: ExcludeSemantics(
          child: DecoratedBox(
            key: const ValueKey('felix-ring'),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: felixSelected ? palette.accent : Colors.transparent,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/felix_avatar.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
      icon(4, Icons.person_outline, Icons.person, 'Profile'),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.tabBar,
        border: Border(top: BorderSide(color: palette.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 48,
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
