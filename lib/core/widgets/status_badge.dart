import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Pill badge whose colours follow the web app's status-badge mapping
/// (frontend/src/components/ui/status-badge.tsx and the dashboard stock pills).
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key, this.small = false});

  final String? status;
  final bool small;

  static ({Color fg, Color bg, String label}) styleFor(String? raw) {
    final s = (raw ?? '').toUpperCase().trim();
    switch (s) {
      case 'COMPLETED':
      case 'PAID':
      case 'ACT':
      case 'ACTIVE':
      case 'AVAILABLE':
      case 'IN_STOCK':
      case 'RECEIVED':
      case 'ACCEPTED':
      case 'APPROVED':
      case 'SUCCESS':
        return (fg: AppColors.success, bg: AppColors.successSoft, label: _label(s));
      case 'PENDING':
      case 'PARTIAL':
      case 'LOW_STOCK':
      case 'LOW':
      case 'ORDERED':
      case 'SENT':
      case 'DRAFT':
      case 'INT':
      case 'PARTIALLY_RETURNED':
      case 'PARTIAL_RETURNED':
        return (fg: AppColors.warning, bg: AppColors.warningSoft, label: _label(s));
      case 'CANCELLED':
      case 'CANCELED':
      case 'RETURNED':
      case 'OUT_STOCK':
      case 'OUT_OF_STOCK':
      case 'OUT':
      case 'DEL':
      case 'DELETED':
      case 'REJECTED':
      case 'EXPIRED':
      case 'UNPAID':
      case 'FAILED':
        return (fg: AppColors.danger, bg: AppColors.dangerSoft, label: _label(s));
      case 'SOLD':
      case 'CONVERTED':
        return (fg: AppColors.info, bg: AppColors.infoSoft, label: _label(s));
      default:
        return (fg: AppColors.neutral, bg: AppColors.neutralSoft, label: _label(s));
    }
  }

  static String _label(String s) {
    switch (s) {
      case 'COMPLETED':
        return tr('mobile.status_completed');
      case 'PENDING':
        return tr('mobile.status_pending');
      case 'CANCELLED':
      case 'CANCELED':
        return tr('mobile.status_cancelled');
      case 'RETURNED':
        return tr('mobile.status_returned');
      case 'PARTIALLY_RETURNED':
      case 'PARTIAL_RETURNED':
        return tr('mobile.status_partially_returned');
      case 'PAID':
        return tr('mobile.status_paid');
      case 'PARTIAL':
        return tr('mobile.status_partial');
      case 'UNPAID':
        return tr('mobile.status_unpaid');
      case 'RECEIVED':
        return tr('mobile.status_received');
      case 'ORDERED':
        return tr('mobile.status_ordered');
      case 'DRAFT':
        return tr('mobile.status_draft');
      case 'SENT':
        return tr('mobile.status_sent');
      case 'ACCEPTED':
        return tr('mobile.status_accepted');
      case 'REJECTED':
        return tr('mobile.status_rejected');
      case 'EXPIRED':
        return tr('mobile.status_expired');
      case 'CONVERTED':
        return tr('mobile.status_converted');
      case 'AVAILABLE':
        return tr('mobile.status_available');
      case 'SOLD':
        return tr('mobile.status_sold');
      case 'IN_STOCK':
        return tr('mobile.in_stock');
      case 'LOW_STOCK':
      case 'LOW':
        return tr('mobile.low');
      case 'OUT_STOCK':
      case 'OUT_OF_STOCK':
      case 'OUT':
        return tr('mobile.out_of_stock');
      case 'ACT':
      case 'ACTIVE':
        return tr('common.active');
      case 'INT':
        return tr('common.inactive');
      case 'DEL':
      case 'DELETED':
        return tr('common.delete');
      case '':
        return '-';
      default:
        return s[0] + s.substring(1).toLowerCase().replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = styleFor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        style.label,
        style: AppTheme.text(
          size: small ? 10.5 : 11.5,
          weight: FontWeight.w700,
          color: style.fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Simple coloured pill with custom text (e.g. "Stock 8", "Low 2").
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, required this.fg, required this.bg, this.icon});

  final String text;
  final Color fg;
  final Color bg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AppTheme.text(size: 11.5, weight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }
}
