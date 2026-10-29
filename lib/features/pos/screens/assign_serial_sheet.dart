import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/status_badge.dart';
import '../../catalog/models.dart';
import '../cart_controller.dart';
import '../pos_providers.dart';
import 'scanner_screen.dart';

class SerialSelection {
  const SerialSelection(this.ids, this.labels);
  final List<int> ids;
  final Map<int, String> labels;
}

/// Bottom sheet (design screen 5): scan or tick one available serial per unit.
Future<SerialSelection?> showAssignSerialSheet(BuildContext context, WidgetRef ref, CartLine line) {
  return showModalBottomSheet<SerialSelection>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AssignSerialSheet(line: line),
  );
}

class _AssignSerialSheet extends ConsumerStatefulWidget {
  const _AssignSerialSheet({required this.line});
  final CartLine line;

  @override
  ConsumerState<_AssignSerialSheet> createState() => _AssignSerialSheetState();
}

class _AssignSerialSheetState extends ConsumerState<_AssignSerialSheet> {
  late List<int> _selected = [...widget.line.serialIds];
  final _scanCtrl = TextEditingController();

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  void _toggle(ProductSerial s) {
    setState(() {
      if (_selected.contains(s.id)) {
        _selected.remove(s.id);
      } else if (_selected.length < widget.line.qty) {
        _selected.add(s.id);
      } else {
        showToast(context, context.t('mobile.serial_selected',
            {'selected': _selected.length, 'needed': widget.line.qty}), error: true);
      }
    });
  }

  void _matchCode(String code, List<ProductSerial> available) {
    final needle = code.trim().toLowerCase();
    if (needle.isEmpty) return;
    final match = available.where((s) => (s.barcode ?? '').trim().toLowerCase() == needle).firstOrNull;
    if (match == null) {
      showToast(context, '${context.t('mobile.product_not_found')}: $code', error: true);
      return;
    }
    if (!_selected.contains(match.id)) _toggle(match);
    _scanCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    final storeId = ref.watch(cartProvider.select((c) => c.storeId));
    final serials = ref.watch(posSerialsProvider(line.product.id));
    final complete = _selected.length == line.qty;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(context.t('pos.assign_serial'),
                          style: AppTheme.text(size: 20, weight: FontWeight.w700)),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(line.product.displayName,
                                style: AppTheme.text(size: 15, weight: FontWeight.w700),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('${context.t('pos.col_qty')} ${line.qty} · ${Fmt.money(line.price)}',
                                style: AppTheme.text(size: 12.5, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Pill(
                        context.t(complete ? 'mobile.serial_selected' : 'mobile.serial_needed',
                            {'selected': _selected.length, 'needed': line.qty}),
                        fg: complete ? AppColors.success : AppColors.warning,
                        bg: complete ? AppColors.successSoft : AppColors.warningSoft,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _scanCtrl,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: context.t('mobile.scan_serial'),
                          prefixIcon: const Icon(Icons.qr_code_2, color: AppColors.textMuted),
                        ),
                        onSubmitted: (v) {
                          final rows = serials.valueOrNull;
                          if (rows != null) _matchCode(v, CartController.availableSerials(rows, storeId));
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    SquareIconButton(
                      icon: Icons.qr_code_scanner_rounded,
                      filled: true,
                      size: 50,
                      onTap: () async {
                        final code = await ScannerScreen.scan(context, title: context.t('pos.assign_serial'));
                        final rows = serials.valueOrNull;
                        if (code != null && rows != null && mounted) {
                          _matchCode(code, CartController.availableSerials(rows, storeId));
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: AsyncView<List<ProductSerial>>(
                  value: serials,
                  onRetry: () => ref.invalidate(posSerialsProvider(line.product.id)),
                  data: (rows) {
                    final available = CartController.availableSerials(rows, storeId)
                        .where((s) => s.isSerialised)
                        .toList();
                    if (available.isEmpty) {
                      return EmptyView(title: context.t('mobile.no_serials'), icon: Icons.qr_code_2);
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      itemCount: available.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => setState(() {
                                _selected = available.take(line.qty).map((s) => s.id).toList();
                              }),
                              icon: const Icon(Icons.auto_awesome, size: 16),
                              label: Text('Auto-fill (${line.qty})'),
                            ),
                          );
                        }
                        final s = available[i - 1];
                        final checked = _selected.contains(s.id);
                        return AppCard(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          borderColor: checked ? AppColors.navy : AppColors.border,
                          color: checked ? AppColors.surfaceMuted : AppColors.surface,
                          onTap: () => _toggle(s),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: checked ? AppColors.navy : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: checked ? AppColors.navy : AppColors.textMuted, width: 1.5),
                                ),
                                child: checked ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.barcode ?? 'SN-${s.id}',
                                        style: AppTheme.text(size: 15, weight: FontWeight.w700, letterSpacing: 0.5)),
                                    Text(
                                      [s.storeName, if (s.createdAt != null) 'received ${Fmt.date(s.createdAt)}']
                                          .whereType<String>()
                                          .join(' · '),
                                      style: AppTheme.text(size: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(s.status),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: ElevatedButton(
                  onPressed: () {
                    final rows = serials.valueOrNull ?? const <ProductSerial>[];
                    final labels = {
                      for (final s in rows)
                        if (_selected.contains(s.id)) s.id: s.barcode ?? 'SN-${s.id}',
                    };
                    Navigator.pop(context, SerialSelection(_selected, labels));
                  },
                  child: Text(context.t('mobile.done')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
