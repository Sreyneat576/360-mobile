import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../router/app_router.dart';
import '../../finance/models.dart';
import '../../finance/repository.dart';
import '../../sales/models.dart';
import '../../sales/repository.dart';
import '../cart_controller.dart';
import '../pos_providers.dart';

/// Payment (design screen 6): method, paying amount with quick cash, change
/// or due, then `POST /sales`. The backend records the payment row itself
/// when `paidAmount > 0`, so no separate `/payments` call is needed.
class PosPaymentScreen extends ConsumerStatefulWidget {
  const PosPaymentScreen({super.key});

  @override
  ConsumerState<PosPaymentScreen> createState() => _PosPaymentScreenState();
}

class _PosPaymentScreenState extends ConsumerState<PosPaymentScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _method = PaymentMethod.cash;
  Bank? _bank;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = Fmt.amount(ref.read(cartProvider).grandTotal).replaceAll(',', '');
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  double get _paying => double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;

  List<double> _quickAmounts(double total) {
    final set = <double>{total};
    for (final step in [5, 10, 20, 50, 100]) {
      final next = ((total / step).floor() + 1) * step.toDouble();
      if (next > total) set.add(next);
      if (set.length >= 4) break;
    }
    final list = set.toList()..sort();
    return list.take(4).toList();
  }

  Future<void> _submit() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;
    if (_method == PaymentMethod.bank && _bank == null) {
      showToast(context, context.t('mobile.bank_required'), error: true);
      return;
    }
    setState(() => _submitting = true);
    try {
      final repo = ref.read(salesRepositoryProvider);
      final customerId = cart.customer?.id ?? (await repo.walkInCustomer()).id;
      final paid = _paying.clamp(0, double.infinity).toDouble();
      final request = ref.read(cartProvider.notifier).buildRequest(
            customerId: customerId,
            // The backend computes change (returnAmount) from the full tender.
            paidAmount: paid,
            paymentMethod: _method,
            bankId: _method == PaymentMethod.bank ? _bank!.id : null,
            note: _noteCtrl.text.trim(),
          );
      final sale = await repo.create(request);
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(posProductsProvider);
      if (!mounted) return;
      await _showSuccess(sale, paid);
      if (mounted) context.go(Routes.pos);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message, error: true);
    } catch (e) {
      if (mounted) showToast(context, context.t('mobile.sale_failed'), error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showSuccess(Sale sale, double paid) {
    final change = (paid - sale.total).clamp(0, double.infinity);
    final due = (sale.total - paid).clamp(0, double.infinity);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: AppColors.successSoft, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: AppColors.success, size: 36),
            ),
            const SizedBox(height: 14),
            Text(ctx.t('mobile.sale_completed'), style: AppTheme.text(size: 18, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(sale.displayNo, style: AppTheme.text(size: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            KeyValueRow(ctx.t('pos.total_payable'), Fmt.money(sale.total)),
            KeyValueRow(ctx.t('pos.paying_amount'), Fmt.money(paid)),
            if (change > 0)
              KeyValueRow(ctx.t('pos.change'), Fmt.money(change), valueColor: AppColors.success, bold: true),
            if (due > 0)
              KeyValueRow(ctx.t('pos.due'), Fmt.money(due), valueColor: AppColors.danger, bold: true),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.t('mobile.new_sale')),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final banks = ref.watch(banksProvider);
    final total = cart.grandTotal;
    final paying = _paying;
    final change = paying - total;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.cart),
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.t('pos.payment_title'), style: AppTheme.text(size: 22, weight: FontWeight.w700)),
            Text(context.t('pos.payment_subtitle'),
                style: AppTheme.text(size: 12.5, color: AppColors.textSecondary)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            decoration: BoxDecoration(
              gradient: AppColors.navyGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Text(context.t('pos.total_payable').toUpperCase(),
                    style: AppTheme.text(size: 12, weight: FontWeight.w700, color: AppColors.onDarkMuted, letterSpacing: 1.2)),
                const SizedBox(height: 6),
                Text(Fmt.money(total),
                    style: AppTheme.text(size: 40, weight: FontWeight.w800, color: Colors.white, height: 1.1)),
                const SizedBox(height: 8),
                Text(
                  '${cart.customer?.name ?? context.t('pos.walk_in_customer')} · ${cart.storeName ?? ''} · '
                  '${context.t('mobile.items_count', {'count': cart.totalItems})}',
                  style: AppTheme.text(size: 12.5, color: AppColors.onDarkMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionTitle(context.t('pos.payment_type'), padding: const EdgeInsets.only(bottom: 8)),
          Row(
            children: [
              Expanded(
                child: _MethodButton(
                  icon: Icons.payments_outlined,
                  label: context.t('pos.cash'),
                  selected: _method == PaymentMethod.cash,
                  onTap: () => setState(() => _method = PaymentMethod.cash),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MethodButton(
                  icon: Icons.account_balance_outlined,
                  label: context.t('nav.bank'),
                  selected: _method == PaymentMethod.bank,
                  onTap: () => setState(() => _method = PaymentMethod.bank),
                ),
              ),
            ],
          ),
          if (_method == PaymentMethod.bank) ...[
            const SizedBox(height: 12),
            banks.when(
              data: (list) => PickerField(
                value: _bank?.name,
                hint: context.t('pos.select_bank'),
                icon: Icons.expand_more,
                onTap: () async {
                  final picked = await showPickerSheet<Bank>(
                    context,
                    title: context.t('pos.select_bank'),
                    items: list,
                    labelOf: (b) => b.name,
                    subtitleOf: (b) => [b.accountName, b.accountNumber].whereType<String>().join(' · '),
                    selected: _bank,
                  );
                  if (picked != null) setState(() => _bank = picked);
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(e.toString(), style: AppTheme.text(size: 12, color: AppColors.danger)),
            ),
          ],
          const SizedBox(height: 18),
          SectionTitle(context.t('pos.paying_amount'), padding: const EdgeInsets.only(bottom: 8)),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            style: AppTheme.text(size: 28, weight: FontWeight.w700),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixText: r'$ ',
              prefixStyle: AppTheme.text(size: 26, weight: FontWeight.w600, color: AppColors.textMuted),
              suffixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.neutralSoft, borderRadius: BorderRadius.circular(8)),
                  child: Text('USD', style: AppTheme.text(size: 12, weight: FontWeight.w700, color: AppColors.textSecondary)),
                ),
              ),
              suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
          ),
          const SizedBox(height: 14),
          SectionTitle(context.t('pos.quick_cash'), padding: const EdgeInsets.only(bottom: 8)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final amount in _quickAmounts(total))
                ChoiceChip(
                  label: Text(Fmt.money(amount)),
                  selected: (paying - amount).abs() < 0.005,
                  labelStyle: AppTheme.text(
                    size: 13,
                    weight: FontWeight.w600,
                    color: (paying - amount).abs() < 0.005 ? Colors.white : AppColors.textPrimary,
                  ),
                  onSelected: (_) => setState(() => _amountCtrl.text = amount.toStringAsFixed(2)),
                ),
              ChoiceChip(
                label: Text('\$0 · ${context.t('pos.due')}'),
                selected: paying == 0,
                labelStyle: AppTheme.text(size: 13, weight: FontWeight.w600,
                    color: paying == 0 ? Colors.white : AppColors.textPrimary),
                onSelected: (_) => setState(() => _amountCtrl.text = '0'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              children: [
                KeyValueRow(context.t('pos.total_payable'), Fmt.money(total)),
                KeyValueRow(context.t('pos.paying_amount'), Fmt.money(paying)),
                const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider()),
                if (change >= 0)
                  KeyValueRow(context.t('pos.change'), Fmt.money(change), bold: true, valueColor: AppColors.success)
                else
                  KeyValueRow(context.t('pos.due'), Fmt.money(-change), bold: true, valueColor: AppColors.danger),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            decoration: InputDecoration(hintText: context.t('common.notes')),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: ElevatedButton.icon(
            onPressed: _submitting || cart.isEmpty ? null : _submit,
            icon: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_outline, size: 20),
            label: Text(context.t('pos.submit_payment')),
          ),
        ),
      ),
    );
  }
}

class _MethodButton extends StatelessWidget {
  const _MethodButton({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 18),
      borderColor: selected ? AppColors.navy : AppColors.border,
      color: selected ? AppColors.surfaceMuted : AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: AppColors.textPrimary),
          const SizedBox(width: 10),
          Text(label, style: AppTheme.text(size: 16, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}
