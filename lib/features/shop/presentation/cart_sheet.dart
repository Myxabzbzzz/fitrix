import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/i18n/catalog_text.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/features/shop/presentation/shop_screen.dart';
import 'package:fitrix/features/shop/providers.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Opens the cart. "Place order" runs [onPlaceOrder] with the sheet still
/// open (button disabled while [busy]) and closes the sheet when it is done.
Future<void> showCartSheet(
  BuildContext context, {
  required ValueListenable<bool> busy,
  required Future<void> Function() onPlaceOrder,
}) =>
    showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      enableDrag: false, // a drag-down would bypass the in-flight guard
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      builder: (_) => CartSheet(busy: busy, onPlaceOrder: onPlaceOrder),
    );

class CartSheet extends ConsumerWidget {
  const CartSheet({super.key, required this.busy, required this.onPlaceOrder});

  final ValueListenable<bool> busy;
  final Future<void> Function() onPlaceOrder;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ValueListenableBuilder<bool>(
        valueListenable: busy,
        // No dismissing (barrier, back, close) while an order is in flight.
        builder: (context, working, _) => PopScope(
          canPop: !working,
          child: _content(context, ref, working),
        ),
      );

  Widget _content(BuildContext context, WidgetRef ref, bool working) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final cart = ref.watch(cartProvider);
    final text = ref.watch(catalogTextProvider);
    final catalog = [
      for (final p in ref.watch(productsProvider).valueOrNull ?? const [])
        text.product(p),
    ];
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
                  onPressed: working ? null : () => Navigator.of(context).pop(),
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
                      color: palette.sheetTile, borderRadius: AppRadius.smAll),
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
              ValueListenableBuilder<bool>(
                valueListenable: busy,
                builder: (context, working, _) => Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: l10n.shopPlaceOrder,
                        size: AppButtonSize.large,
                        expand: true,
                        onPressed: working
                            ? null
                            : () async {
                                await onPlaceOrder();
                                // Only close our own sheet, never a page
                                // underneath it.
                                if (context.mounted &&
                                    ModalRoute.of(context)?.isCurrent == true) {
                                  Navigator.of(context).pop();
                                }
                              },
                      ),
                    ),
                    if (working) ...[
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        key: const Key('order-progress'),
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: palette.accent),
                      ),
                    ],
                  ],
                ),
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
