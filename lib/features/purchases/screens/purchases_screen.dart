import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/network/paged.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/status_badge.dart';
import '../models.dart';
import '../repository.dart';

/// Purchases list as cards (reference, supplier, store, date, totals, payment
/// and purchase status) with a detail sheet showing the line items and
/// received serials.
class PurchasesScreen extends ConsumerStatefulWidget {
  const PurchasesScreen({super.key});

  @override
  ConsumerState<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {
  final _items = <Purchase>[];
  final _scroll = ScrollController();
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  Object? _error;
  String _query = '';
  String? _status; // null = all, COMPLETED, CANCELLED
  String? _paymentStatus;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) _load();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    if (reset) {
      _page = 1;
      _hasMore = true;
      _items.clear();
      _error = null;
    }
    if (!_hasMore) return;
    setState(() => _loading = true);
    try {
      final Paged<Purchase> result = await ref.read(purchasesRepositoryProvider).purchases(
            page: _page,
            size: 20,
            status: _status,
            paymentStatus: _paymentStatus,
          );
      _items.addAll(result.data);
      _hasMore = result.hasMore && result.data.isNotEmpty;
      _page++;
    } catch (e) {
      _error = e;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final visible = q.isEmpty
        ? _items
        : _items.where((p) {
            return (p.referenceNo ?? '').toLowerCase().contains(q) ||
                (p.supplierName ?? '').toLowerCase().contains(q) ||
                (p.storeName ?? '').toLowerCase().contains(q);
          }).toList();

    final filters = <(String?, String?, String)>[
      (null, null, context.t('common.all')),
      ('COMPLETED', null, context.t('mobile.status_completed')),
      (null, 'PAID', context.t('mobile.status_paid')),
      (null, 'PARTIAL', context.t('mobile.status_partial')),
      (null, 'PENDING', context.t('mobile.status_pending')),
      ('CANCELLED', null, context.t('mobile.status_cancelled')),
    ];
    final selectedFilter = filters.firstWhere(
      (f) => f.$1 == _status && f.$2 == _paymentStatus,
      orElse: () => filters.first,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(
              title: context.t('nav.purchases'),
              subtitle: context.t('nav.purchase'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SearchField(
                hint: context.t('common.search'),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 12),
            FilterChips<(String?, String?, String)>(
              items: filters,
              selected: selectedFilter,
              labelOf: (f) => f.$3,
              onSelected: (f) {
                setState(() {
                  _status = f.$1;
                  _paymentStatus = f.$2;
                });
                _load(reset: true);
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _error != null && _items.isEmpty
                  ? ErrorView(error: _error!, onRetry: () => _load(reset: true))
                  : _items.isEmpty && _loading
                      ? const LoadingView()
                      : visible.isEmpty
                          ? EmptyView(title: context.t('common.no_results'), icon: Icons.shopping_bag_outlined)
                          : RefreshIndicator(
                              onRefresh: () => _load(reset: true),
                              child: ListView.separated(
                                controller: _scroll,
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemCount: visible.length + (_hasMore ? 1 : 0),
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  if (i >= visible.length) {
                                    return const LoadingView(padding: EdgeInsets.all(16));
                                  }
                                  final p = visible[i];
                                  return _PurchaseCard(
                                    purchase: p,
                                    onTap: () => showModalBottomSheet<void>(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (_) => _PurchaseDetailSheet(purchaseId: p.id),
                                    ),
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

class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({required this.purchase, required this.onTap});
  final Purchase purchase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = purchase;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(p.referenceNo ?? 'PUR-${p.id}',
                    style: AppTheme.text(size: 16, weight: FontWeight.w700, letterSpacing: 0.3)),
              ),
              StatusBadge(p.paymentStatus, small: true),
              const SizedBox(width: 6),
              StatusBadge(p.status, small: true),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _Meta(Icons.groups_outlined, p.supplierName ?? '-'),
              _Meta(Icons.storefront_outlined, p.storeName ?? '-'),
              _Meta(Icons.calendar_today_outlined, Fmt.date(p.purchaseDate)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Expanded(child: _Amount(context.t('mobile.total'), Fmt.money(p.grandTotal))),
                Expanded(child: _Amount(context.t('mobile.paid'), Fmt.money(p.paidAmount))),
                Expanded(
                  child: _Amount(context.t('mobile.due'), Fmt.money(p.due),
                      color: p.due > 0 ? AppColors.danger : null),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(text, style: AppTheme.text(size: 12.5, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount(this.label, this.value, {this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: AppTheme.text(size: 10.5, weight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.6)),
        const SizedBox(height: 2),
        Text(value, style: AppTheme.text(size: 14.5, weight: FontWeight.w700, color: color ?? AppColors.textPrimary),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _PurchaseDetailSheet extends ConsumerWidget {
  const _PurchaseDetailSheet({required this.purchaseId});
  final int purchaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(purchaseDetailProvider(purchaseId));
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: AsyncView<Purchase>(
          value: detail,
          onRetry: () => ref.invalidate(purchaseDetailProvider(purchaseId)),
          data: (p) => ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(p.referenceNo ?? 'PUR-${p.id}',
                        style: AppTheme.text(size: 20, weight: FontWeight.w700)),
                  ),
                  StatusBadge(p.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${p.supplierName ?? '-'} · ${p.storeName ?? '-'} · ${Fmt.date(p.purchaseDate)}',
                style: AppTheme.text(size: 13, color: AppColors.textSecondary),
              ),
              if ((p.note ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(p.note!, style: AppTheme.text(size: 13, color: AppColors.textSecondary)),
              ],
              const SizedBox(height: 16),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < p.items.length; i++) ...[
                      if (i > 0) const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(p.items[i].productName ?? 'Product #${p.items[i].productId}',
                                      style: AppTheme.text(size: 14, weight: FontWeight.w700)),
                                ),
                                Text(Fmt.money(p.items[i].subtotal),
                                    style: AppTheme.text(size: 14, weight: FontWeight.w700)),
                              ],
                            ),
                            Text(
                              '${Fmt.qty(p.items[i].quantity)} × ${Fmt.money(p.items[i].cost)}',
                              style: AppTheme.text(size: 12, color: AppColors.textSecondary),
                            ),
                            if (p.items[i].serialNumbers.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final s in p.items[i].serialNumbers)
                                    if ((s.barcode ?? '').isNotEmpty)
                                      Pill(s.barcode!, fg: AppColors.textSecondary, bg: AppColors.neutralSoft),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  children: [
                    KeyValueRow(context.t('pos.summary_subtotal'), Fmt.money(p.total)),
                    KeyValueRow(context.t('pos.summary_discount'), Fmt.money(p.discount)),
                    KeyValueRow(context.t('pos.summary_grand_total'), Fmt.money(p.grandTotal), bold: true),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Divider()),
                    KeyValueRow(context.t('mobile.paid'), Fmt.money(p.paidAmount), valueColor: AppColors.success),
                    KeyValueRow(context.t('mobile.due'), Fmt.money(p.due),
                        valueColor: p.due > 0 ? AppColors.danger : null),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Text(context.t('mobile.payment_status'),
                              style: AppTheme.text(color: AppColors.textSecondary)),
                          const Spacer(),
                          StatusBadge(p.paymentStatus),
                        ],
                      ),
                    ),
                    if (p.bankName != null)
                      KeyValueRow(context.t('nav.bank'), p.bankName!),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
