import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/app_strings.dart';
import '../network/api_exception.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// White rounded container with the standard border, used everywhere the
/// design shows a card.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color = AppColors.surface,
    this.borderColor = AppColors.border,
    this.radius = AppTheme.radius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final Color borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// Page title + subtitle block used at the top of each tab.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.text(size: 24, weight: FontWeight.w700)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: AppTheme.text(size: 13, color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Square icon button with white background and border (header actions).
class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.badge,
    this.filled = false,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final int? badge;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: filled ? AppColors.navy : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: filled ? null : Border.all(color: AppColors.border),
              ),
              child: Icon(
                icon,
                size: 21,
                color: filled ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
        if (badge != null && badge! > 0)
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$badge',
                style: AppTheme.text(size: 11, weight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

/// Rounded search input used on list screens.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.trailing,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 22),
        suffixIcon: trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

/// Horizontal scrollable list of selectable chips.
class FilterChips<T> extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.items,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<T> items;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          final isSelected = item == selected;
          return ChoiceChip(
            label: Text(labelOf(item)),
            selected: isSelected,
            onSelected: (_) => onSelected(item),
            labelStyle: AppTheme.text(
              size: 13,
              weight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          );
        },
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing, this.padding});

  final String text;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: AppTheme.text(
                size: 11.5,
                weight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Label on the left, value on the right.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow(
    this.label,
    this.value, {
    super.key,
    this.valueColor,
    this.bold = false,
    this.labelWidget,
    this.valueWidget,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;
  final Widget? labelWidget;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: labelWidget ??
                Text(
                  label,
                  style: AppTheme.text(
                    size: bold ? 16 : 14,
                    weight: bold ? FontWeight.w700 : FontWeight.w400,
                    color: bold ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
          ),
          valueWidget ??
              Text(
                value,
                style: AppTheme.text(
                  size: bold ? 20 : 14,
                  weight: bold ? FontWeight.w700 : FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
        ],
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.padding = const EdgeInsets.all(48)});
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.neutralSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            Text(title, style: AppTheme.text(size: 15, weight: FontWeight.w600), textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: AppTheme.text(size: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final message = error is ApiException ? error.toString() : context.t('mobile.something_wrong');
    final forbidden = error is ApiException && (error as ApiException).isForbidden;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: AppColors.dangerSoft, shape: BoxShape.circle),
              child: Icon(
                forbidden ? Icons.lock_outline : Icons.error_outline,
                size: 30,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              forbidden ? context.t('mobile.no_permission') : message,
              style: AppTheme.text(size: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null && !forbidden) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(context.t('mobile.retry')),
                style: OutlinedButton.styleFrom(minimumSize: const Size(140, 44)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Renders an AsyncValue with the standard loading/error/data states.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loading,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => loading ?? const LoadingView(),
      error: (e, _) => ErrorView(error: e, onRetry: onRetry),
      skipLoadingOnRefresh: true,
    );
  }
}

/// Small coloured square with an icon (used for product thumbnails and
/// module tiles when no image is available).
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.color = AppColors.info,
    this.background = AppColors.infoSoft,
    this.size = 48,
    this.radius = 12,
    this.iconSize,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final double size;
  final double radius;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, color: color, size: iconSize ?? size * 0.48),
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.initials, this.size = 44, this.image});

  final String initials;
  final double size;
  final Widget? image;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
      child: image ??
          Center(
            child: Text(
              initials,
              style: AppTheme.text(
                size: size * 0.36,
                weight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
    );
  }
}

/// Shows a snackbar from anywhere with a BuildContext.
void showToast(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.danger : AppColors.textPrimary,
        duration: Duration(seconds: error ? 4 : 2),
      ),
    );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  String? confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: AppTheme.text(size: 17, weight: FontWeight.w700)),
      content: message == null
          ? null
          : Text(message, style: AppTheme.text(size: 14, color: AppColors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(ctx.t('common.cancel'), style: AppTheme.text(weight: FontWeight.w600, color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            confirmLabel ?? ctx.t('mobile.confirm'),
            style: AppTheme.text(
              weight: FontWeight.w700,
              color: destructive ? AppColors.danger : AppColors.navy,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Standard screen with back button in the app bar.
class SubScaffold extends StatelessWidget {
  const SubScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions,
    this.bottom,
    this.floatingActionButton,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottom;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: AppTheme.text(size: 20, weight: FontWeight.w700)),
            if (subtitle != null)
              Text(subtitle!, style: AppTheme.text(size: 12.5, color: AppColors.textSecondary)),
          ],
        ),
        actions: actions == null ? null : [...actions!, const SizedBox(width: 8)],
      ),
      body: body,
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: bottom,
              ),
            ),
      floatingActionButton: floatingActionButton,
    );
  }
}

/// Form field wrapper with a small uppercase label above.
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child, this.required = false});

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: RichText(
            text: TextSpan(
              text: label.toUpperCase(),
              style: AppTheme.text(
                size: 11,
                weight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.6,
              ),
              children: [
                if (required)
                  TextSpan(text: ' *', style: AppTheme.text(size: 11, weight: FontWeight.w700, color: AppColors.danger)),
              ],
            ),
          ),
        ),
        child,
        const SizedBox(height: 14),
      ],
    );
  }
}

/// Bottom-sheet picker for a list of options.
Future<T?> showPickerSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> items,
  required String Function(T) labelOf,
  String? Function(T)? subtitleOf,
  T? selected,
  bool searchable = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _PickerSheet<T>(
      title: title,
      items: items,
      labelOf: labelOf,
      subtitleOf: subtitleOf,
      selected: selected,
      searchable: searchable,
    ),
  );
}

class _PickerSheet<T> extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.items,
    required this.labelOf,
    this.subtitleOf,
    this.selected,
    required this.searchable,
  });

  final String title;
  final List<T> items;
  final String Function(T) labelOf;
  final String? Function(T)? subtitleOf;
  final T? selected;
  final bool searchable;

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final items = q.isEmpty
        ? widget.items
        : widget.items.where((e) {
            final sub = widget.subtitleOf?.call(e) ?? '';
            return widget.labelOf(e).toLowerCase().contains(q) || sub.toLowerCase().contains(q);
          }).toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  children: [
                    Expanded(child: Text(widget.title, style: AppTheme.text(size: 18, weight: FontWeight.w700))),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              if (widget.searchable)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SearchField(
                    hint: context.t('common.search'),
                    onChanged: (v) => setState(() => _query = v),
                    autofocus: false,
                  ),
                ),
              Flexible(
                child: items.isEmpty
                    ? EmptyView(title: context.t('common.no_results'))
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, i) {
                          final item = items[i];
                          final isSelected = item == widget.selected;
                          final sub = widget.subtitleOf?.call(item);
                          return ListTile(
                            title: Text(widget.labelOf(item), style: AppTheme.text(weight: FontWeight.w600)),
                            subtitle: sub == null || sub.isEmpty ? null : Text(sub, style: AppTheme.text(size: 12, color: AppColors.textSecondary)),
                            trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.navy) : null,
                            onTap: () => Navigator.pop(context, item),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Input that opens a picker sheet, styled like a text field.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.value,
    required this.hint,
    required this.onTap,
    this.onClear,
    this.icon = Icons.expand_more,
  });

  final String? value;
  final String hint;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          suffixIcon: hasValue && onClear != null
              ? IconButton(onPressed: onClear, icon: const Icon(Icons.close, size: 18))
              : Icon(icon, color: AppColors.textMuted),
        ),
        child: Text(
          hasValue ? value! : hint,
          style: AppTheme.text(color: hasValue ? AppColors.textPrimary : AppColors.textMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
