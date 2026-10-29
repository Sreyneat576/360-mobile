import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/api_image.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/status_badge.dart';
import '../../pos/pos_providers.dart';
import '../models.dart';
import '../repository.dart';

/// Product list: search by name/code/brand, category filter, price, cost and
/// stock. Tapping a product opens a detail sheet with its serial rows.
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _query = '';
  int? _categoryId;

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(posProductsProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(
              title: context.t('product.title'),
              subtitle: products.valueOrNull == null
                  ? null
                  : context.t('mobile.products_count', {'count': products.valueOrNull!.length}),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SearchField(
                hint: context.t('pos.search_placeholder'),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 12),
            categories.when(
              data: (list) => FilterChips<int?>(
                items: [null, ...list.map((c) => c.id)],
                selected: _categoryId,
                labelOf: (id) =>
                    id == null ? context.t('common.all') : list.firstWhere((c) => c.id == id).name,
                onSelected: (id) => setState(() => _categoryId = id),
              ),
              loading: () => const SizedBox(height: 40),
              error: (_, __) => const SizedBox.shrink(),
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
                    if (categoryName != null && (p.categoryName ?? '').toLowerCase() != categoryName) {
                      return false;
                    }
                    if (q.isEmpty) return true;
                    return p.displayName.toLowerCase().contains(q) ||
                        (p.code ?? '').toLowerCase().contains(q) ||
                        (p.brandName ?? '').toLowerCase().contains(q) ||
                        (p.modelName ?? '').toLowerCase().contains(q);
                  }).toList();
                  if (filtered.isEmpty) {
                    return EmptyView(title: context.t('common.no_results'), icon: Icons.search_off);
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(posProductsProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _ProductTile(
                        product: filtered[i],
                        onTap: () => _showDetail(context, filtered[i]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, Product product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProductDetailSheet(product: product),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final level = product.isOutOfStock
        ? 'OUT_STOCK'
        : product.isLowStock
            ? 'LOW_STOCK'
            : 'IN_STOCK';
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          ApiImage(
            source: product.imageUrl,
            bucket: 'product',
            width: 56,
            height: 56,
            placeholder: const IconTile(
              icon: Icons.smartphone_outlined,
              size: 56,
              color: AppColors.textSecondary,
              background: AppColors.neutralSoft,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.displayName,
                    style: AppTheme.text(size: 14.5, weight: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  [product.code, product.brandName, product.categoryName]
                      .whereType<String>()
                      .where((s) => s.isNotEmpty)
                      .join(' · '),
                  style: AppTheme.text(size: 12, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(Fmt.money(product.price), style: AppTheme.text(size: 15, weight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text('${context.t('mobile.cost')} ${Fmt.money(product.costPrice)}',
                        style: AppTheme.text(size: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Fmt.qty(product.stock), style: AppTheme.text(size: 18, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              StatusBadge(level, small: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductDetailSheet extends ConsumerWidget {
  const _ProductDetailSheet({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serials = ref.watch(productSerialsProvider(product.id));
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ApiImage(
                  source: product.imageUrl,
                  bucket: 'product',
                  width: 72,
                  height: 72,
                  placeholder: const IconTile(
                    icon: Icons.smartphone_outlined,
                    size: 72,
                    color: AppColors.textSecondary,
                    background: AppColors.neutralSoft,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.displayName, style: AppTheme.text(size: 18, weight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(product.code ?? '-', style: AppTheme.text(size: 12.5, color: AppColors.textMuted)),
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        if (product.categoryName != null)
                          Pill(product.categoryName!, fg: AppColors.info, bg: AppColors.infoSoft),
                        if (product.brandName != null)
                          Pill(product.brandName!, fg: AppColors.pink, bg: AppColors.pinkSoft),
                        if (product.modelName != null)
                          Pill(product.modelName!, fg: AppColors.neutral, bg: AppColors.neutralSoft),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _Stat(context.t('mobile.sale_price'), Fmt.money(product.salePrice), AppColors.success)),
                const SizedBox(width: 10),
                Expanded(child: _Stat(context.t('mobile.cost_price'), Fmt.money(product.costPrice), AppColors.danger)),
                const SizedBox(width: 10),
                Expanded(child: _Stat(context.t('pos.stock_qty'), Fmt.qty(product.stock), AppColors.textPrimary)),
              ],
            ),
            if (product.reorderLevel != null) ...[
              const SizedBox(height: 10),
              Text('${context.t('product.reorder_level')}: ${product.reorderLevel}',
                  style: AppTheme.text(size: 12.5, color: AppColors.textSecondary)),
            ],
            if (product.variantValues.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(context.t('mobile.variants').toUpperCase(),
                  style: AppTheme.text(size: 11, weight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final v in product.variantValues)
                    Pill('${v.variantTypeName ?? ''}${v.variantTypeName != null ? ': ' : ''}${v.name}',
                        fg: AppColors.textSecondary, bg: AppColors.neutralSoft),
                ],
              ),
            ],
            if ((product.noted ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(product.noted!, style: AppTheme.text(size: 13, color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 16),
            Text(context.t('mobile.serials').toUpperCase(),
                style: AppTheme.text(size: 11, weight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            AsyncView<List<ProductSerial>>(
              value: serials,
              onRetry: () => ref.invalidate(productSerialsProvider(product.id)),
              loading: const LoadingView(padding: EdgeInsets.all(16)),
              data: (rows) {
                if (rows.isEmpty) {
                  return Text(context.t('common.no_results'),
                      style: AppTheme.text(size: 13, color: AppColors.textMuted));
                }
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < rows.length; i++) ...[
                        if (i > 0) const Divider(),
                        ListTile(
                          dense: true,
                          title: Text(rows[i].barcode ?? 'Lot #${rows[i].id}',
                              style: AppTheme.text(size: 14, weight: FontWeight.w700, letterSpacing: 0.4)),
                          subtitle: Text(
                            '${rows[i].storeName ?? '-'} · ${context.t('pos.col_qty')} ${Fmt.qty(rows[i].quantity)} · ${Fmt.money(rows[i].price)}',
                            style: AppTheme.text(size: 12, color: AppColors.textSecondary),
                          ),
                          trailing: StatusBadge(rows[i].status, small: true),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTheme.text(size: 16, weight: FontWeight.w700, color: color),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.text(size: 11, color: AppColors.textSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
