import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/features/shop/presentation/shop_screen.dart';
import 'package:fitrix/features/shop/providers.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Opens the cart. Completes with true when the user taps "Place order"
/// (the sheet is closed first so the result is visible on the shop screen).
Future<bool?> showCartSheet(BuildContext context) => showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppPalette.of(context).sheet,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      builder: (_) => const CartSheet(),
    );

class CartSheet extends ConsumerWidget {
  const CartSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final cart = ref.watch(cartProvider);
    final catalog = ref.watch(productsProvider).valueOrNull ?? const [];
    // Only lines that are still in the catalog are shown and ordered.
    final lines = [
      for (final p in catalog)
        if ((cart[p.id] ?? 0) > 0) p,
    ];
    final totalCents =
        lines.fold<int>(0, (a, p) => a + p.priceCents * cart[p.id]!);
    final currency = lines.isEmpty ? 'USD' : lines.first.currency;
    final notifier = ref.read(cartProvider.notifier);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l10n.shopCartTitle,
                      style: AppText.headingM
                          .copyWith(color: palette.textPrimary)),
                ),
                IconButton(
                  tooltip: l10n.shopClose,
                  icon: const Icon(Icons.close_rounded),
                  color: palette.textPrimary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            if (lines.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(l10n.shopCartEmpty,
                    style: AppText.bodyRegular
                        .copyWith(color: palette.textSecondary)),
              )
            else ...[
              for (final p in lines)
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                      color: palette.tile, borderRadius: AppRadius.smAll),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name,
                                style: AppText.bodyStrong
                                    .copyWith(color: palette.textPrimary)),
                            Text(formatMoney(context, p.priceCents, p.currency),
                                style: AppText.caption
                                    .copyWith(color: palette.textSecondary)),
                          ],
                        ),
                      ),
                      _QtyButton(
                        key: Key('cart-dec-${p.id}'),
                        icon: Icons.remove_rounded,
                        label: l10n.shopRemoveOne,
                        onTap: () => notifier.remove(p.id),
                      ),
                      SizedBox(
                        width: 32,
                        child: Text('${cart[p.id]}',
                            textAlign: TextAlign.center,
                            style: AppText.bodyStrong
                                .copyWith(color: palette.textPrimary)),
                      ),
                      _QtyButton(
                        key: Key('cart-inc-${p.id}'),
                        icon: Icons.add_rounded,
                        label: l10n.shopAddOne,
                        onTap: () => notifier.add(p.id),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.shopTotal,
                        style: AppText.body14
                            .copyWith(color: palette.textSecondary)),
                  ),
                  Text(formatMoney(context, totalCents, currency),
                      style: AppText.headingM
                          .copyWith(color: palette.textPrimary)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l10n.shopPlaceOrder,
                size: AppButtonSize.large,
                expand: true,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  color: palette.buttonMuted, shape: BoxShape.circle),
              child: Icon(icon, size: 16, color: palette.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
