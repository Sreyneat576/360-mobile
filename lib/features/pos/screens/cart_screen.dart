import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../sales/models.dart';
import '../../sales/repository.dart';
import '../cart_controller.dart';
import 'assign_serial_sheet.dart';

/// Cart review (design screen 4): customer, lines with quantity steppers and
/// serial status, totals, and the Payment action.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Future<void> _pickCustomer(BuildContext context, WidgetRef ref) async {
    List<Customer> customers;
    try {
      customers = await ref.read(customersProvider.future);
    } catch (e) {
      if (context.mounted) showToast(context, e.toString(), error: true);
      return;
    }
    if (!context.mounted) return;
    final walkIn = Customer(id: 0, name: context.t('pos.walk_in_customer'));
    final current = ref.read(cartProvider).customer;
    final picked = await showPickerSheet<Customer>(
      context,
      title: context.t('pos.select_customer'),
      items: [walkIn, ...customers],
      labelOf: (c) => c.name,
      subtitleOf: (c) => [c.code, c.phone].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
      selected: current ?? walkIn,
      searchable: true,
    );
    if (picked == null) return;
    ref.read(cartProvider.notifier).setCustomer(picked.id == 0 ? null : picked);
  }

  Future<void> _addCustomer(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final result = await showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ctx.t('pos.add_customer'), style: AppTheme.text(size: 18, weight: FontWeight.w700)),
            const SizedBox(height: 16),
            LabeledField(
              label: ctx.t('mobile.customer_name'),
              required: true,
              child: TextField(controller: nameCtrl, autofocus: true, textCapitalization: TextCapitalization.words),
            ),
            LabeledField(
              label: ctx.t('mobile.phone'),
              child: TextField(controller: phoneCtrl, keyboardType: TextInputType.phone),
            ),
            _SubmitButton(
              label: ctx.t('common.save'),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final code = 'C${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
                final created = await ref.read(salesRepositoryProvider).createCustomer(
                      CustomerRequest(code: code, name: name, phone: phoneCtrl.text.trim()),
                    );
                ref.invalidate(customersProvider);
                if (ctx.mounted) Navigator.pop(ctx, created);
              },
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    phoneCtrl.dispose();
    if (result != null) ref.read(cartProvider.notifier).setCustomer(result);
  }

  Future<void> _editDiscount(BuildContext context, WidgetRef ref) async {
    final cart = ref.read(cartProvider);
    final value = await _promptAmount(
      context,
      title: context.t('pos.discount_title'),
      initial: cart.discount,
      max: cart.subtotal,
    );
    if (value != null) ref.read(cartProvider.notifier).setDiscount(value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final productCount = cart.lines.length;

    return Scaffold(
      appBar: AppBar(
        leading: const _BackButton(),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.t('mobile.cart'), style: AppTheme.text(size: 22, weight: FontWeight.w700)),
            Text(
              '${context.t('mobile.products_count', {'count': productCount})} · '
              '${context.t('mobile.items_count', {'count': cart.totalItems})}',
              style: AppTheme.text(size: 12.5, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: cart.isEmpty
                ? null
                : () async {
                    final ok = await confirmDialog(context,
                        title: context.t('pos.btn_reset'),
                        message: context.t('pos.empty_cart').replaceAll('Add products first.', ''),
                        destructive: true);
                    if (ok) ref.read(cartProvider.notifier).clear();
                  },
            child: Text(context.t('pos.btn_reset'),
                style: AppTheme.text(weight: FontWeight.w700, color: AppColors.danger)),
          ),
        ],
      ),
      body: cart.isEmpty
          ? EmptyView(
              title: context.t('pos.cart_empty_title'),
              subtitle: context.t('pos.cart_empty_desc'),
              icon: Icons.shopping_cart_outlined,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const IconTile(icon: Icons.person_outline, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickCustomer(context, ref),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.t('pos.customer'),
                                  style: AppTheme.text(size: 12, color: AppColors.textSecondary)),
                              Text(
                                cart.customer?.name ?? context.t('pos.walk_in_customer'),
                                style: AppTheme.text(size: 15, weight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _addCustomer(context, ref),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.infoSoft,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: const StadiumBorder(),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(context.t('pos.add_customer')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < cart.lines.length; i++) ...[
                        if (i > 0) const Divider(),
                        _CartLineTile(line: cart.lines[i]),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    children: [
                      KeyValueRow(context.t('pos.summary_items'), '${cart.totalItems}'),
                      KeyValueRow(context.t('pos.summary_subtotal'), Fmt.money(cart.subtotal)),
                      KeyValueRow(
                        context.t('pos.summary_discount'),
                        cart.discount > 0 ? '– ${Fmt.money(cart.discount)}' : Fmt.money(0),
                        valueColor: cart.discount > 0 ? AppColors.danger : null,
                        labelWidget: Row(
                          children: [
                            Text(context.t('pos.summary_discount'),
                                style: AppTheme.text(color: AppColors.textSecondary)),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _editDiscount(context, ref),
                              child: Text(context.t('common.edit'),
                                  style: AppTheme.text(size: 13, weight: FontWeight.w700, color: AppColors.info)),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Divider(),
                      ),
                      KeyValueRow(context.t('pos.summary_grand_total'), Fmt.money(cart.grandTotal), bold: true),
                    ],
                  ),
                ),
                if (!cart.serialsComplete)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warningSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(context.t('mobile.serial_required'),
                                style: AppTheme.text(size: 12.5, color: AppColors.warning)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: ElevatedButton.icon(
                  onPressed: cart.serialsComplete ? () => context.push(Routes.posPayment) : null,
                  icon: const Icon(Icons.credit_card_outlined, size: 20),
                  label: Text('${context.t('pos.btn_payment')} · ${Fmt.money(cart.grandTotal)}'),
                ),
              ),
            ),
    );
  }
}

class _CartLineTile extends ConsumerWidget {
  const _CartLineTile({required this.line});
  final CartLine line;

  Future<void> _openSerials(BuildContext context, WidgetRef ref) async {
    final result = await showAssignSerialSheet(context, ref, line);
    if (result != null) {
      ref.read(cartProvider.notifier).setSerials(line.product.id, result.ids, result.labels);
    }
  }

  Future<void> _editLine(BuildContext context, WidgetRef ref) async {
    final price = await _promptAmount(context, title: context.t('pos.unit_price'), initial: line.price);
    if (price == null || !context.mounted) return;
    ref.read(cartProvider.notifier).setPrice(line.product.id, price);
    final disc = await _promptAmount(context,
        title: context.t('pos.item_discount'), initial: line.itemDiscount, max: price * line.qty);
    if (disc != null) ref.read(cartProvider.notifier).setItemDiscount(line.product.id, disc);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);
    final p = line.product;
    final serialChip = switch (line.requiresSerial) {
      true => line.serialsComplete
          ? Pill(
              context.t('mobile.serial_selected', {'selected': line.serialIds.length, 'needed': line.qty}),
              fg: AppColors.success,
              bg: AppColors.successSoft,
              icon: Icons.qr_code_2)
          : Pill(
              context.t('mobile.serial_needed', {'selected': line.serialIds.length, 'needed': line.qty}),
              fg: AppColors.warning,
              bg: AppColors.warningSoft,
              icon: Icons.qr_code_2),
      false => null,
      null => Pill('…', fg: AppColors.textMuted, bg: AppColors.neutralSoft, icon: Icons.qr_code_2),
    };

    return Dismissible(
      key: ValueKey('line-${p.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.dangerSoft,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      onDismissed: (_) => notifier.remove(p.id),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ApiImage(
              source: p.imageUrl,
              bucket: 'product',
              width: 52,
              height: 52,
              placeholder: const IconTile(icon: Icons.smartphone_outlined, size: 52,
                  color: AppColors.textSecondary, background: AppColors.neutralSoft),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.displayName, style: AppTheme.text(size: 14.5, weight: FontWeight.w700),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: () => _editLine(context, ref),
                    child: Text(
                      '${Fmt.money(line.price)}${line.itemDiscount > 0 ? ' − ${Fmt.money(line.itemDiscount)}' : ''}'
                      '${p.code != null ? ' · ${p.code}' : ''}',
                      style: AppTheme.text(size: 12, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (serialChip != null) ...[
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _openSerials(context, ref),
                      borderRadius: BorderRadius.circular(999),
                      child: serialChip,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(Fmt.money(line.subtotal), style: AppTheme.text(size: 15, weight: FontWeight.w700)),
                const SizedBox(height: 8),
                _Stepper(
                  value: line.qty,
                  max: p.stock > 0 ? p.stock.floor() : null,
                  onChanged: (v) => notifier.setQty(p.id, v),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged, this.max});
  final int value;
  final int? max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final canInc = max == null || value < max!;
    return Container(
      height: 34,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(icon: Icons.remove, onTap: () => onChanged(value - 1)),
          SizedBox(
            width: 34,
            child: Center(child: Text('$value', style: AppTheme.text(size: 14, weight: FontWeight.w700))),
          ),
          _StepBtn(icon: Icons.add, filled: true, onTap: canInc ? () => onChanged(value + 1) : null),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap, this.filled = false});
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.navy : Colors.transparent,
      borderRadius: BorderRadius.horizontal(
        left: filled ? Radius.zero : const Radius.circular(8),
        right: filled ? const Radius.circular(8) : Radius.zero,
      ),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 16,
              color: onTap == null ? AppColors.textMuted : (filled ? Colors.white : AppColors.textPrimary)),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => context.canPop() ? context.pop() : context.go(Routes.pos),
      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
    );
  }
}

class _SubmitButton extends StatefulWidget {
  const _SubmitButton({required this.label, required this.onPressed});
  final String label;
  final Future<void> Function() onPressed;

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _busy
          ? null
          : () async {
              setState(() => _busy = true);
              try {
                await widget.onPressed();
              } catch (e) {
                if (mounted) showToast(context, e.toString(), error: true);
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
      child: _busy
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(widget.label),
    );
  }
}

Future<double?> _promptAmount(BuildContext context,
    {required String title, double initial = 0, double? max}) async {
  final ctrl = TextEditingController(text: initial == 0 ? '' : Fmt.qty(initial));
  final result = await showDialog<double>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: AppTheme.text(size: 17, weight: FontWeight.w700)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        decoration: const InputDecoration(prefixText: r'$ '),
        onSubmitted: (v) => Navigator.pop(ctx, double.tryParse(v) ?? 0),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.t('common.cancel'))),
        TextButton(
          onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text) ?? 0),
          child: Text(ctx.t('pos.apply')),
        ),
      ],
    ),
  );
  ctrl.dispose();
  if (result == null) return null;
  final v = result.clamp(0, max ?? double.infinity).toDouble();
  return v;
}
