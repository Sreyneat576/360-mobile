import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/api_image.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../router/app_router.dart';
import '../../auth/auth_controller.dart';
import '../../catalog/models.dart';
import '../../catalog/repository.dart';
import '../../inventory/models.dart';
import '../../inventory/repository.dart';
import '../cart_controller.dart';
import '../pos_providers.dart';
import 'scanner_screen.dart';

/// POS terminal (design screen 3): search, camera scan, category chips,
/// product cards with stock badge and in-cart count, cart bar.
class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  int? _categoryId; // null = all
  bool _scanning = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    if (_scanning) return;
    final products = ref.read(posProductsProvider).valueOrNull;
    if (products == null) return;
    final code = await ScannerScreen.scan(context);
    if (code == null || !mounted) return;
    setState(() => _scanning = true);
    try {
      final product = await resolveScannedCode(ref.read(apiClientProvider), code, products);
      if (!mounted) return;
      if (product == null) {
        showToast(context, '${context.t('mobile.product_not_found')}: $code', error: true);
      } else {
        _add(product);
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  void _add(Product product) {
    if (product.isOutOfStock) {
      showToast(context, '${product.displayName}: ${context.t('pos.out_of_stock')}', error: true);
      return;
    }
    final inCart = ref.read(cartProvider).qtyOf(product.id);
    if (inCart + 1 > product.stock) {
      showToast(context, context.t('mobile.stock_not_enough', {'qty': Fmt.qty(product.stock)}), error: true);
      return;
    }
    ref.read(cartProvider.notifier).add(product);
    showToast(context, '${product.displayName} · ${context.t('mobile.added_to_cart')}');
  }

  Future<void> _pickStore(List<Store> stores) async {
    final cart = ref.read(cartProvider);
    final selected = await showPickerSheet<Store>(
      context,
      title: context.t('mobile.select_store'),
      items: stores,
      labelOf: (s) => s.name,
      subtitleOf: (s) => s.code,
      selected: stores.where((s) => s.id == cart.storeId).firstOrNull,
    );
    if (selected != null) ref.read(cartProvider.notifier).setStore(selected.id, selected.name);
  }

  Future<void> _logout() async {
    final ok = await confirmDialog(context,
        title: context.t('user.logout'), message: context.t('mobile.logout_confirm'), destructive: true);
    if (ok) await ref.read(authProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final cart = ref.watch(cartProvider);
    final products = ref.watch(posProductsProvider);
    final categories = ref.watch(categoriesProvider);
    final stores = ref.watch(storesProvider);

    // Default the store to the first one once loaded (web POS behaviour).
    ref.listen(storesProvider, (_, next) {
      final list = next.valueOrNull;
      if (list != null && list.isNotEmpty && ref.read(cartProvider).storeId == null) {
        ref.read(cartProvider.notifier).setStore(list.first.id, list.first.name);
      }
    });

    final storeName = cart.storeName ?? stores.valueOrNull?.firstOrNull?.name ?? '—';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(
              title: context.t('pos.terminal'),
              subtitle: context.t('mobile.pos_subtitle', {
                'store': storeName,
                'seller': user?.displayName ?? '',
              }),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SquareIconButton(
                    icon: Icons.storefront_outlined,
                    onTap: stores.valueOrNull == null ? null : () => _pickStore(stores.valueOrNull!),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'lang') ref.read(languageProvider.notifier).toggle();
                      if (v == 'logout') _logout();
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'lang',
                        child: Row(children: [
                          const Icon(Icons.language, size: 18),
                          const SizedBox(width: 10),
                          Text('${ctx.t('mobile.language')}: ${L10n.current == AppLanguage.en ? 'EN' : 'KM'}'),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'logout',
                        child: Row(children: [
                          const Icon(Icons.logout, size: 18, color: AppColors.danger),
                          const SizedBox(width: 10),
                          Text(ctx.t('user.logout'), style: AppTheme.text(color: AppColors.danger)),
                        ]),
                      ),
                    ],
                    child: UserAvatar(initials: user?.initials ?? '?', size: 44),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: SearchField(
                      controller: _searchCtrl,
                      hint: context.t('pos.search_placeholder'),
                      onChanged: (v) => setState(() => _query = v),
                      trailing: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SquareIconButton(
                    icon: Icons.qr_code_scanner_rounded,
                    filled: true,
                    size: 50,
                    onTap: _scanning ? null : _scan,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            categories.when(
              data: (list) => FilterChips<int?>(
                items: [null, ...list.map((c) => c.id)],
                selected: _categoryId,
                labelOf: (id) => id == null
                    ? context.t('pos.all_categories')
                    : list.firstWhere((c) => c.id == id).name,
                onSelected: (id) => setState(() => _categoryId = id),
              ),
              loading: () => const SizedBox(height: 40),
              error: (_, __) => const SizedBox(height: 0),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AsyncView<List<Product>>(
                value: products,
                onRetry: () => ref.invalidate(posProductsProvider),
                data: (list) {
                  final categoryName = _categoryId == null
                      ? null
                      : categories.valueOrNull
                          ?.where((c) => c.id == _categoryId)
                          .firstOrNull
                          ?.name
                          .toLowerCase();
                  final q = _query.trim().toLowerCase();
                  final filtered = list.where((p) {
                    if (categoryName != null &&
                        (p.categoryName ?? '').toLowerCase() != categoryName) {
                      return false;
                    }
                    if (q.isEmpty) return true;
                    return p.displayName.toLowerCase().contains(q) ||
                        (p.code ?? '').toLowerCase().contains(q) ||
                        (p.brandName ?? '').toLowerCase().contains(q);
                  }).toList();
                  if (filtered.isEmpty) {
                    return EmptyView(
                      title: context.t('pos.no_products'),
                      subtitle: context.t('pos.no_products_desc'),
                      icon: Icons.search_off,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(posProductsProvider),
                    child: GridView.builder(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, cart.isEmpty ? 16 : 96),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final p = filtered[i];
                        return _ProductCard(
                          product: p,
                          inCart: cart.qtyOf(p.id),
                          onTap: () => _add(p),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomSheet: cart.isEmpty ? null : _CartBar(cart: cart),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.inCart, required this.onTap});

  final Product product;
  final int inCart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stockPill = product.isOutOfStock
        ? Pill(context.t('mobile.out_of_stock'), fg: AppColors.danger, bg: AppColors.dangerSoft)
        : product.isLowStock
            ? Pill('${context.t('mobile.low')} ${Fmt.qty(product.stock)}',
                fg: AppColors.warning, bg: AppColors.warningSoft)
            : Pill('${context.t('pos.stock_qty')} ${Fmt.qty(product.stock)}',
                fg: AppColors.success, bg: AppColors.successSoft);

    return AppCard(
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ApiImage(
                    source: product.imageUrl,
                    bucket: 'product',
                    radius: 10,
                    placeholder: const IconTile(
                      icon: Icons.smartphone_outlined,
                      size: double.infinity,
                      radius: 10,
                      color: AppColors.textSecondary,
                      background: AppColors.neutralSoft,
                      iconSize: 40,
                    ),
                  ),
                ),
                if (inCart > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
                      child: Text('$inCart',
                          style: AppTheme.text(size: 12, weight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.text(size: 13.5, weight: FontWeight.w700),
          ),
          Text(
            product.code ?? product.brandName ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.text(size: 11.5, color: AppColors.textMuted, letterSpacing: 0.3),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  Fmt.money(product.price),
                  style: AppTheme.text(size: 15, weight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              stockPill,
            ],
          ),
        ],
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  const _CartBar({required this.cart});
  final CartState cart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Material(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => context.push(Routes.cart),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('${cart.totalItems}',
                              style: AppTheme.text(size: 11, weight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.t('mobile.items_in_cart', {'count': cart.totalItems}),
                            style: AppTheme.text(size: 12, color: AppColors.onDarkMuted)),
                        Text(Fmt.money(cart.grandTotal),
                            style: AppTheme.text(size: 19, weight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  ),
                  Text(context.t('mobile.view_cart'),
                      style: AppTheme.text(size: 15, weight: FontWeight.w700, color: const Color(0xFFFFB38A))),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward, color: Color(0xFFFFB38A), size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
