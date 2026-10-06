import 'package:flutter/material.dart';
import 'package:fitrix/core/navigation/circle_reveal.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/widgets/feature_tile.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';

/// "My workouts": grid of sports, each opening its list of workouts.
class MyWorkoutsScreen extends StatelessWidget {
  const MyWorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenTitle('My workouts'),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.fromLTRB(31, 8, 31, 24),
                crossAxisCount: 2,
                mainAxisSpacing: 17,
                crossAxisSpacing: 17,
                childAspectRatio: 148 / 96,
                children: [
                  for (final sport in Sport.values)
                    Builder(
                      // The tile's own context, so the reveal starts there.
                      builder: (tileContext) => FeatureTile(
                        label: sport.tileLabel,
                        imageAsset: sport.imageAsset,
                        imageWidthFactor: 0.6,
                        labelAlignment: Alignment.topLeft,
                        imageAlignment: Alignment.bottomRight,
                        onTap: () => openWithReveal(
                          tileContext,
                          AppRouter.sportWorkouts(sport),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
