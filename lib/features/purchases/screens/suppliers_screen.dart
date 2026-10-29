import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/permissions.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/auth_controller.dart';
import '../models.dart';
import '../repository.dart';

/// Suppliers: searchable list with create, edit and delete (permission-gated).
class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  String _query = '';

  Future<void> _openForm({Supplier? supplier}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SupplierForm(supplier: supplier),
    );
    if (saved == true) {
      ref.invalidate(suppliersProvider);
      if (mounted) showToast(context, context.t('mobile.saved'));
    }
  }

  Future<void> _delete(Supplier s) async {
    final ok = await confirmDialog(
      context,
      title: context.t('confirm.delete.title'),
      message: context.t('confirm.delete.desc'),
      confirmLabel: context.t('confirm.delete.confirm'),
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(purchasesRepositoryProvider).deleteSupplier(s.id);
      ref.invalidate(suppliersProvider);
      if (mounted) showToast(context, context.t('mobile.deleted'));
    } catch (e) {
      if (mounted) showToast(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final suppliers = ref.watch(suppliersProvider);
    final canCreate = user?.can(Perm.supplierCreate) ?? false;
    final canUpdate = user?.can(Perm.supplierUpdate) ?? false;
    final canDelete = user?.can(Perm.supplierDelete) ?? false;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(
              title: context.t('nav.suppliers'),
              subtitle: suppliers.valueOrNull == null
                  ? null
                  : '${suppliers.valueOrNull!.length} ${context.t('common.entries')}',
              trailing: canCreate
                  ? SquareIconButton(icon: Icons.add, filled: true, onTap: () => _openForm())
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SearchField(
                hint: context.t('common.search'),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: AsyncView<List<Supplier>>(
                value: suppliers,
                onRetry: () => ref.invalidate(suppliersProvider),
                data: (list) {
                  final q = _query.trim().toLowerCase();
                  final filtered = q.isEmpty
                      ? list
                      : list.where((s) {
                          return s.name.toLowerCase().contains(q) ||
                              (s.code ?? '').toLowerCase().contains(q) ||
                              (s.phone ?? '').toLowerCase().contains(q) ||
                              (s.email ?? '').toLowerCase().contains(q);
                        }).toList();
                  if (filtered.isEmpty) {
                    return EmptyView(title: context.t('common.no_results'), icon: Icons.groups_outlined);
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(suppliersProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final s = filtered[i];
                        return AppCard(
                          padding: const EdgeInsets.all(12),
                          onTap: canUpdate ? () => _openForm(supplier: s) : null,
                          child: Row(
                            children: [
                              UserAvatar(initials: Fmt.initials(s.name), size: 46),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(s.name,
                                              style: AppTheme.text(size: 15, weight: FontWeight.w700),
                                              maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                        StatusBadge(s.status, small: true),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      [s.code, s.phone, s.email]
                                          .whereType<String>()
                                          .where((e) => e.isNotEmpty)
                                          .join(' · '),
                                      style: AppTheme.text(size: 12.5, color: AppColors.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if ([s.address, s.city, s.country].any((e) => (e ?? '').isNotEmpty))
                                      Text(
                                        [s.address, s.city, s.country]
                                            .whereType<String>()
                                            .where((e) => e.isNotEmpty)
                                            .join(', '),
                                        style: AppTheme.text(size: 12, color: AppColors.textMuted),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              if (canDelete)
                                IconButton(
                                  onPressed: () => _delete(s),
                                  icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                                ),
                            ],
                          ),
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
    );
  }
}

class _SupplierForm extends ConsumerStatefulWidget {
  const _SupplierForm({this.supplier});
  final Supplier? supplier;

  @override
  ConsumerState<_SupplierForm> createState() => _SupplierFormState();
}

class _SupplierFormState extends ConsumerState<_SupplierForm> {
  final _formKey = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.supplier?.code ?? '');
  late final _name = TextEditingController(text: widget.supplier?.name ?? '');
  late final _phone = TextEditingController(text: widget.supplier?.phone ?? '');
  late final _email = TextEditingController(text: widget.supplier?.email ?? '');
  late final _address = TextEditingController(text: widget.supplier?.address ?? '');
  late final _city = TextEditingController(text: widget.supplier?.city ?? '');
  late final _country = TextEditingController(text: widget.supplier?.country ?? '');
  late final _note = TextEditingController(text: widget.supplier?.note ?? '');
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_code, _name, _phone, _email, _address, _city, _country, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(purchasesRepositoryProvider);
      final request = SupplierRequest(
        code: _code.text.trim(),
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        address: _address.text.trim(),
        city: _city.text.trim(),
        country: _country.text.trim(),
        note: _note.text.trim(),
        // PUT must resend status or the backend nulls it (see analysis doc).
        status: widget.supplier?.status ?? 'ACT',
      );
      if (widget.supplier == null) {
        await repo.createSupplier(request);
      } else {
        await repo.updateSupplier(widget.supplier!.id, request);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showToast(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.supplier != null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                Text(context.t(isEdit ? 'mobile.edit_supplier' : 'mobile.new_supplier'),
                    style: AppTheme.text(size: 18, weight: FontWeight.w700)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: LabeledField(
                        label: context.t('common.code'),
                        required: true,
                        child: TextFormField(
                          controller: _code,
                          textCapitalization: TextCapitalization.characters,
                          validator: (v) => (v == null || v.trim().isEmpty) ? context.t('mobile.required') : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: LabeledField(
                        label: context.t('mobile.supplier_name'),
                        required: true,
                        child: TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v == null || v.trim().isEmpty) ? context.t('mobile.required') : null,
                        ),
                      ),
                    ),
                  ],
                ),
                LabeledField(
                  label: context.t('mobile.phone'),
                  child: TextFormField(controller: _phone, keyboardType: TextInputType.phone),
                ),
                LabeledField(
                  label: context.t('mobile.email'),
                  child: TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      return v.contains('@') ? null : context.t('mobile.invalid_email');
                    },
                  ),
                ),
                LabeledField(
                  label: context.t('mobile.address'),
                  child: TextFormField(controller: _address),
                ),
                Row(
                  children: [
                    Expanded(
                      child: LabeledField(label: 'City', child: TextFormField(controller: _city)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LabeledField(label: 'Country', child: TextFormField(controller: _country)),
                    ),
                  ],
                ),
                LabeledField(
                  label: context.t('common.notes'),
                  child: TextFormField(controller: _note, maxLines: 2),
                ),
                ElevatedButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(context.t('common.save')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
