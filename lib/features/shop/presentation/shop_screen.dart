import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/i18n/catalog_text.dart';
import 'package:fitrix/core/widgets/sheet_safe_area.dart';
import 'package:fitrix/core/widgets/app_snack.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:fitrix/core/supabase/supabase_providers.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/pill_selector.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/auth/presentation/sign_in_prompt.dart';
import 'package:fitrix/features/content/data/content_repository.dart';
import 'package:fitrix/features/shop/presentation/cart_sheet.dart';
import 'package:fitrix/features/shop/providers.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// "$54.00" for a price in cents.
String formatMoney(BuildContext context, int cents, String currency) =>
    NumberFormat.simpleCurrency(
      locale: Localizations.localeOf(context).toString(),
      name: currency,
    ).format(cents / 100);

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  static const _all = '';
  final _search = TextEditingController();
  String _category = _all;
  final _busy = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _search.dispose();
    _busy.dispose();
    super.dispose();
  }

  String _categoryLabel(AppLocalizations l10n, String c) => switch (c) {
        _all => l10n.shopAll,
        'supplements' => l10n.shopCatSupplements,
        'equipment' => l10n.shopCatEquipment,
        'apparel' => l10n.shopCatApparel,
        _ => c.isEmpty ? c : c[0].toUpperCase() + c.substring(1),
      };

  Future<void> _openCart() => showCartSheet(
        context,
        busy: _busy,
        onPlaceOrder: _placeOrder,
      );

  Future<void> _placeOrder() async {
    if (_busy.value) return;
    final l10n = AppLocalizations.of(context);

    void promptSignIn() =>
        showSignInPrompt(context, ref, l10n.shopSignInToOrder);

    if (ref.read(currentUserProvider).valueOrNull == null) {
      return promptSignIn();
    }
    final catalog = ref.read(productsProvider).valueOrNull ?? const [];
    final ids = {for (final p in catalog) p.id};
    final cartNotifier = ref.read(cartProvider.notifier);
    // The cart can hold products that left the catalog: don't order them.
    final lines = {
      for (final e in ref.read(cartProvider).entries)
        if (ids.contains(e.key)) e.key: e.value,
    };
    if (lines.isEmpty) return;
    final repo = ref.read(shopRepositoryProvider);

    _busy.value = true;
    try {
      await repo.placeOrder(lines);
      // Remove only what was ordered: items added meanwhile stay.
      for (final e in lines.entries) {
        for (var i = 0; i < e.value; i++) {
          cartNotifier.remove(e.key);
        }
      }
      if (mounted) showAppSnack(context, l10n.shopOrderPlaced);
    } on SignInRequired {
      if (mounted) promptSignIn();
    } on OrderException catch (e) {
      debugPrint('Order rejected: ${e.message}');
      if (mounted) {
        showAppSnack(context, l10n.shopOrderUnavailable);
      }
    } catch (_) {
      if (mounted) _retryBar(l10n);
    } finally {
      if (mounted) _busy.value = false;
    }
  }

  void _retryBar(AppLocalizations l10n) => showAppSnack(
        context,
        l10n.shopOrderFailed,
        action: SnackBarAction(label: l10n.shopRetry, onPressed: _placeOrder),
      );

  void _showPro() {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      showDragHandle: true,
      builder: (ctx) => SheetSafeArea(
          child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.shopProSoonTitle,
                style: AppText.headingM.copyWith(color: palette.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.shopProSoonBody,
                style:
                    AppText.bodyRegular.copyWith(color: palette.textSecondary)),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: l10n.shopGotIt,
              size: AppButtonSize.large,
              expand: true,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final async = ref.watch(productsProvider);
    final source = async.valueOrNull ?? const <Product>[];
    final text = ref.watch(catalogTextProvider);
    // English names stay searchable next to the app language's.
    final english = {for (final p in source) p.id: p.name.toLowerCase()};
    final products = [for (final p in source) text.product(p)];
    ref.watch(currentUserProvider); // keep the auth state loaded
    final cart = ref.watch(cartProvider);
    final catalogIds = {for (final p in products) p.id};
    // Cart lines for products missing from the catalog stay stored (the
    // catalog may be the seed fallback) but are hidden, not counted and not
    // ordered. Until the catalog has loaded there is no badge.
    final count = cart.entries
        .where((e) => catalogIds.contains(e.key))
        .fold<int>(0, (a, e) => a + e.value);

    final categories = [
      _all,
      for (final c in {for (final p in products) p.category}) c,
    ];
    final category = categories.contains(_category) ? _category : _all;
    final query = _search.text.trim().toLowerCase();
    final items = [
      for (final p in products)
        if ((category == _all || p.category == category) &&
            (query.isEmpty ||
                p.name.toLowerCase().contains(query) ||
                (english[p.id]?.contains(query) ?? false)))
          p,
    ];
    final rows = (items.length + 1) ~/ 2;
    const pad = EdgeInsets.symmetric(horizontal: AppSpacing.md);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenTitle(
              l10n.shopTitle,
              trailing: _CartButton(count: count, onTap: _openCart),
            ),
            Padding(
              padding: pad,
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                style: AppText.body14.copyWith(color: palette.textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.shopSearchHint,
                  hintStyle:
                      AppText.body14.copyWith(color: palette.textSecondary),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 20, color: palette.textSecondary),
                  isDense: true,
                  filled: true,
                  fillColor: palette.tile,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  border: OutlineInputBorder(
                      borderRadius: AppRadius.fullAll,
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            PillSelector<String>(
              items: categories,
              selected: category,
              labelOf: (c) => _categoryLabel(l10n, c),
              onSelected: (c) => setState(() => _category = c),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(productsProvider);
                  await ref.read(productsProvider.future);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                      AppSpacing.md, AppSpacing.md, AppSpacing.lg),
                  children: [
                    if (query.isEmpty && category == _all)
                      _ProCard(onTap: _showPro),
                    if (items.isEmpty && !async.isLoading)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: Text(
                            query.isEmpty
                                ? l10n.shopNoProducts
                                : l10n.shopNothingFound(_search.text.trim()),
                            style: AppText.bodyRegular
                                .copyWith(color: palette.textSecondary)),
                      )
                    else if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    for (var r = 0; r < rows; r++)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _ProductTile(
                                product: items[2 * r],
                                quantity: cart[items[2 * r].id] ?? 0,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: 2 * r + 1 < items.length
                                  ? _ProductTile(
                                      product: items[2 * r + 1],
                                      quantity: cart[items[2 * r + 1].id] ?? 0,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
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

class _CartButton extends StatefulWidget {
  const _CartButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  State<_CartButton> createState() => _CartButtonState();
}

class _CartButtonState extends State<_CartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Motion.slow);
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 60),
    ]).chain(CurveTween(curve: Motion.curve)).animate(_controller);
  }

  @override
  void didUpdateWidget(_CartButton old) {
    super.didUpdateWidget(old);
    if (widget.count > old.count && !Motion.reduced(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return Semantics(
      button: true,
      label: l10n.shopCartLabel(widget.count),
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        key: const Key('cart-button'),
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.shopping_cart_outlined,
                  size: 24, color: palette.textPrimary),
              if (widget.count > 0)
                Positioned(
                  top: AppSpacing.xxs,
                  right: 0,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Container(
                      key: const Key('cart-count'),
                      constraints: const BoxConstraints(minWidth: 18),
                      height: 18,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxs),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: palette.accent,
                          borderRadius: AppRadius.fullAll),
                      child: Text('${widget.count}',
                          style: AppText.microStrong
                              .copyWith(color: palette.onAccent)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProCard extends StatelessWidget {
  const _ProCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return ClipRRect(
      borderRadius: AppRadius.smAll,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        color: palette.tile,
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.accent.withValues(alpha: 0.16)),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(text: 'FITRIX ', children: [
                    TextSpan(
                        text: 'Pro', style: TextStyle(color: palette.accent)),
                  ]),
                  style:
                      AppText.displayLarge.copyWith(color: palette.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.shopProBlurb,
                    style:
                        AppText.caption.copyWith(color: palette.textPrimary)),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: l10n.shopProButton,
                  size: AppButtonSize.small,
                  onPressed: onTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends ConsumerWidget {
  const _ProductTile({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final image = product.image;
    final word = product.word ?? product.name.split(' ').first.toUpperCase();
    final placeholder = Text(word,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.displayLarge.copyWith(color: palette.buttonMuted));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 132,
          decoration:
              BoxDecoration(color: palette.tile, borderRadius: AppRadius.smAll),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Center(
                    child: image == null
                        ? placeholder
                        : Image.asset('assets/images/$image.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => placeholder),
                  ),
                ),
              ),
              Positioned(
                right: AppSpacing.xs,
                bottom: AppSpacing.xs,
                child: Semantics(
                  button: true,
                  label: l10n.shopAdd(product.name),
                  excludeSemantics: true,
                  onTap: () => ref.read(cartProvider.notifier).add(product.id),
                  child: GestureDetector(
                    key: Key('add-${product.id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        ref.read(cartProvider.notifier).add(product.id),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: palette.accent, shape: BoxShape.circle),
                      child: quantity > 0
                          ? Text('$quantity',
                              style: AppText.captionStrong
                                  .copyWith(color: palette.onAccent))
                          : Icon(Icons.add_rounded,
                              size: 20, color: palette.onAccent),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.body14.copyWith(color: palette.textPrimary)),
        Text(formatMoney(context, product.priceCents, product.currency),
            style: AppText.bodyStrong.copyWith(color: palette.textPrimary)),
      ],
    );
  }
}
