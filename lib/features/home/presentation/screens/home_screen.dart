import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/widgets/feature_tile.dart';
import 'package:fitrix/core/widgets/fitrix_logo.dart';

/// Home dashboard from the design: a grid of feature tiles
/// (My progress, My nutrition, Felix, My workouts, Shop, Fitrix map).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const double _gap = 17;

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
                    left: 12,
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
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final half = (constraints.maxWidth - _gap) / 2;
                    final small = (half - _gap) / 2;

                    return Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: half,
                              height: half,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: FeatureTile(
                                      label: 'MY\nPROG\nRESS',
                                      imageAsset: 'assets/images/tile_progress.png',
                                      imageWidthFactor: 0.5,
                                      onTap: () => context.go(AppRouter.progress),
                                    ),
                                  ),
                                  const SizedBox(height: _gap),
                                  Expanded(
                                    child: FeatureTile(
                                      label: 'MY\nNUTRI\nTION',
                                      imageAsset: 'assets/images/tile_nutrition.png',
                                      imageWidthFactor: 0.55,
                                      onTap: () => context.go(AppRouter.nutrition),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: _gap),
                            SizedBox(
                              width: half,
                              height: half,
                              child: FeatureTile(
                                label: 'FELIX',
                                labelSize: 26,
                                imageAsset: 'assets/images/felix_robot.png',
                                imageWidthFactor: 1,
                                imageAlignment: Alignment.center,
                                labelAlignment: Alignment.center,
                                onTap: () => context.go(AppRouter.felix),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: _gap),
                        SizedBox(
                          height: half,
                          child: FeatureTile(
                            label: 'MY\nWORKOUTS',
                            labelSize: 28,
                            imageAsset: 'assets/images/tile_workouts.png',
                            imageWidthFactor: 0.55,
                            onTap: () => context.go(AppRouter.workouts),
                          ),
                        ),
                        const SizedBox(height: _gap),
                        Row(
                          children: [
                            SizedBox(
                              width: half,
                              height: small,
                              child: FeatureTile(
                                label: 'SHOP',
                                labelSize: 20,
                                imageAsset: 'assets/images/tile_shop.png',
                                imageWidthFactor: 0.5,
                                onTap: () => context.go(AppRouter.shop),
                              ),
                            ),
                            const SizedBox(width: _gap),
                            SizedBox(
                              width: half,
                              height: small,
                              child: FeatureTile(
                                label: 'FITRIX\nMAP',
                                labelSize: 18,
                                imageAsset: 'assets/images/tile_map.png',
                                imageWidthFactor: 0.45,
                                onTap: () => context.go(AppRouter.fitrixMap),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
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
            item(Icons.restaurant_outlined, 'My nutrition', AppRouter.nutrition),
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
