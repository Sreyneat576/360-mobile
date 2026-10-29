import 'package:intl/intl.dart';

/// Number and date formatting shared across screens.
class Fmt {
  Fmt._();

  static final NumberFormat _money = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _int = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _compact = NumberFormat.compact(locale: 'en_US');

  /// `$1,466.00`
  static String money(num? value, {String symbol = r'$'}) {
    final v = value ?? 0;
    final sign = v < 0 ? '-' : '';
    return '$sign$symbol${_money.format(v.abs())}';
  }

  /// `1,466.00` without a symbol.
  static String amount(num? value) => _money.format(value ?? 0);

  /// `1,234`
  static String integer(num? value) => _int.format(value ?? 0);

  /// `41.2k`
  static String compact(num? value) => _compact.format(value ?? 0);

  /// Quantity: shows `2` for whole numbers and `2.5` otherwise.
  static String qty(num? value) {
    final v = value ?? 0;
    if (v == v.roundToDouble()) return _int.format(v);
    return v.toStringAsFixed(2);
  }

  static String percent(num? value, {int decimals = 1}) =>
      '${(value ?? 0).toStringAsFixed(decimals)}%';

  // ---------------------------------------------------------------------------
  // Dates. The backend serialises LocalDateTime as `yyyy-MM-dd HH:mm:ss`
  // (spring.jackson.date-format) but some fields are ISO strings.
  // ---------------------------------------------------------------------------

  static DateTime? parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    try {
      return DateTime.parse(text.replaceFirst(' ', 'T'));
    } catch (_) {
      try {
        return DateFormat('yyyy-MM-dd HH:mm:ss').parse(text);
      } catch (_) {
        try {
          return DateFormat('yyyy-MM-dd').parse(text);
        } catch (_) {
          return null;
        }
      }
    }
  }

  /// `6 Oct 2026`
  static String date(dynamic raw) {
    final d = parseDate(raw);
    if (d == null) return '-';
    return DateFormat('d MMM yyyy').format(d);
  }

  /// `6 Oct · 09:32`
  static String dateTimeShort(dynamic raw) {
    final d = parseDate(raw);
    if (d == null) return '-';
    return '${DateFormat('d MMM').format(d)} · ${DateFormat('HH:mm').format(d)}';
  }

  /// `6 Oct 2026, 09:32`
  static String dateTime(dynamic raw) {
    final d = parseDate(raw);
    if (d == null) return '-';
    return DateFormat('d MMM yyyy, HH:mm').format(d);
  }

  /// `Tue, 6 Oct 2026`
  static String longDate(DateTime d) => DateFormat('EEE, d MMM yyyy').format(d);

  /// API query format `yyyy-MM-dd`.
  static String apiDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  /// API body format `yyyy-MM-ddTHH:mm:ss` (LocalDateTime).
  static String apiDateTime(DateTime d) =>
      DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(d);

  /// `Aug 2026`
  static String monthYear(DateTime d) => DateFormat('MMM yyyy').format(d);

  static String initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

/// Tolerant JSON readers used by every model.
extension JsonReaders on Map<String, dynamic> {
  int? intOf(String key) {
    final v = this[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  double? doubleOf(String key) {
    final v = this[key];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  String? stringOf(String key) {
    final v = this[key];
    if (v == null) return null;
    return v.toString();
  }

  bool? boolOf(String key) {
    final v = this[key];
    if (v is bool) return v;
    if (v is String) {
      final l = v.toLowerCase();
      if (l == 'true' || l == 'y' || l == 'yes' || l == '1') return true;
      if (l == 'false' || l == 'n' || l == 'no' || l == '0') return false;
    }
    if (v is num) return v != 0;
    return null;
  }

  List<Map<String, dynamic>> listOf(String key) {
    final v = this[key];
    if (v is List) return v.whereType<Map<String, dynamic>>().toList();
    return const [];
  }

  List<int> intListOf(String key) {
    final v = this[key];
    if (v is List) {
      return v
          .map((e) => e is num ? e.toInt() : int.tryParse(e.toString()))
          .whereType<int>()
          .toList();
    }
    return const [];
  }

  List<String> stringListOf(String key) {
    final v = this[key];
    if (v is List) return v.map((e) => e.toString()).toList();
    return const [];
  }

  Map<String, dynamic>? mapOf(String key) {
    final v = this[key];
    if (v is Map<String, dynamic>) return v;
    return null;
  }
}
