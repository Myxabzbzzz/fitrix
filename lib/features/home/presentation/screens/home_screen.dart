import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/navigation/circle_reveal.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/feature_tile.dart';
import 'package:fitrix/core/widgets/fitrix_logo.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Home dashboard: a grid of feature tiles (My progress, My nutrition, Felix,
/// My workouts, Shop, Fitrix map) and a Today card with the next workout.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const double _small = 64;
  static const double _large = 148;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      drawer: const _HomeDrawer(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 56,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const FitrixLogo(),
                  Positioned(
                    left: AppSpacing.sm,
                    child: Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu),
                        color: palette.textPrimary,
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.lg),
                child: Column(
                  children: [
                    SizedBox(
                      height: _small * 2 + AppSpacing.md,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(
                                  child: _SectionTile(
                                    location: AppRouter.progress,
                                    label: 'MY\nPROGRESS',
                                    labelSize: AppText.displaySmall.fontSize!,
                                    imageAsset:
                                        'assets/images/tile_progress.png',
                                    imageWidthFactor: 0.5,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Expanded(
                                  child: _SectionTile(
                                    location: AppRouter.nutrition,
                                    label: 'MY\nNUTRITION',
                                    labelSize: AppText.displaySmall.fontSize!,
                                    imageAsset:
                                        'assets/images/tile_nutrition.png',
                                    imageWidthFactor: 0.55,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: FeatureTile(
                              label: 'FELIX',
                              labelSize: AppText.displayLarge.fontSize!,
                              imageAsset: 'assets/images/felix_robot.png',
                              imageWidthFactor: 1,
                              imageAlignment: Alignment.center,
                              labelAlignment: Alignment.center,
                              onTap: () => context.go(AppRouter.felix),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: _large,
                      child: _SectionTile(
                        location: AppRouter.workouts,
                        label: 'MY\nWORKOUTS',
                        labelSize: AppText.displayLarge.fontSize!,
                        imageAsset: 'assets/images/tile_workouts.png',
                        imageWidthFactor: 0.55,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: _small,
                      child: Row(
                        children: [
                          Expanded(
                            child: FeatureTile(
                              label: 'SHOP',
                              labelSize: AppText.displayMedium.fontSize!,
                              imageAsset: 'assets/images/tile_shop.png',
                              imageWidthFactor: 0.5,
                              onTap: () => context.go(AppRouter.shop),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _SectionTile(
                              location: AppRouter.fitrixMap,
                              label: 'FITRIX\nMAP',
                              labelSize: AppText.displaySmall.fontSize!,
                              imageAsset: 'assets/images/tile_map.png',
                              imageWidthFactor: 0.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _TodayCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Today's workout (first plan of the user's first sport) with a Start /
/// Continue button.
class _TodayCard extends ConsumerWidget {
  const _TodayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final templates = ref.watch(workoutTemplatesProvider);
    if (templates.isEmpty) return const SizedBox.shrink();
    final today = templates.first;
    final active = ref.watch(activeWorkoutProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration:
          BoxDecoration(color: palette.tile, borderRadius: AppRadius.smAll),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.homeToday.toUpperCase(),
                    style: AppText.microStrong.copyWith(color: palette.accent)),
                Text(today.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppText.headingS.copyWith(color: palette.textPrimary)),
                Text(
                  l10n.homeTodayMeta(today.exercises.length,
                      today.estimatedDuration.inMinutes),
                  style: AppText.caption.copyWith(color: palette.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppButton(
            label: active == null ? l10n.homeStart : l10n.homeContinue,
            size: AppButtonSize.small,
            onPressed: () {
              if (active == null) {
                ref.read(activeWorkoutProvider.notifier).start(today);
              }
              ref.read(activeWorkoutExpandedProvider.notifier).state = true;
            },
          ),
        ],
      ),
    );
  }
}

/// A Home tile that opens one of Home's sections with a circle reveal
/// expanding from the tile.
class _SectionTile extends StatelessWidget {
  final String location;
  final String label;
  final double labelSize;
  final String imageAsset;
  final double imageWidthFactor;

  const _SectionTile({
    required this.location,
    required this.label,
    this.labelSize = 16,
    required this.imageAsset,
    required this.imageWidthFactor,
  });

  @override
  Widget build(BuildContext context) {
    return FeatureTile(
      label: label,
      labelSize: labelSize,
      imageAsset: imageAsset,
      imageWidthFactor: imageWidthFactor,
      onTap: () => openWithReveal(context, location),
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    Widget item(IconData icon, String label, String location) => ListTile(
          leading: Icon(icon, color: palette.textPrimary),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: palette.textPrimary,
            ),
          ),
          onTap: () {
            Navigator.of(context).pop();
            // Not opened from a tile: no circle origin, plain fade instead.
            RevealOrigins.clear(location);
            context.go(location);
          },
        );

    return Drawer(
      backgroundColor: palette.background,
      child: SafeArea(
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: FitrixLogo(),
            ),
            item(Icons.show_chart, 'My progress', AppRouter.progress),
            item(
                Icons.restaurant_outlined, 'My nutrition', AppRouter.nutrition),
            item(Icons.fitness_center, 'My workouts', AppRouter.workouts),
            item(Icons.smart_toy_outlined, 'Felix', AppRouter.felix),
            item(Icons.shopping_cart_outlined, 'Shop', AppRouter.shop),
            item(Icons.map_outlined, 'Fitrix map', AppRouter.fitrixMap),
            item(Icons.person_outline, 'About me', AppRouter.me),
          ],
        ),
      ),
    );
  }
}
