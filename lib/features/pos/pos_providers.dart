import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../catalog/models.dart';
import '../catalog/repository.dart';

/// Every active product, loaded once for the POS and filtered locally
/// (the backend product list only supports exact-match name/code filters).
final posProductsProvider = FutureProvider<List<Product>>(
  (ref) => ref.watch(catalogRepositoryProvider).allProducts(),
);

/// Serial rows for a product, cached per product while the POS is open.
final posSerialsProvider = FutureProvider.family<List<ProductSerial>, int>(
  (ref, productId) => ref.watch(catalogRepositoryProvider).serialsForProduct(productId),
);

/// Resolve a scanned code to a product.
///
/// 1. exact product code (then exact name) among the loaded products;
/// 2. a serial barcode via `GET /reports/product-serials?barcode=` (the
///    `/product-serial?barcode=` filter crashes server-side, the report one
///    works but needs `report:read`; a 403 is silently ignored).
Future<Product?> resolveScannedCode(ApiClient api, String code, List<Product> products) async {
  final needle = code.trim().toLowerCase();
  if (needle.isEmpty) return null;
  for (final p in products) {
    if ((p.code ?? '').trim().toLowerCase() == needle) return p;
  }
  for (final p in products) {
    if ((p.name ?? '').trim().toLowerCase() == needle) return p;
  }
  try {
    final json = await api.get('/reports/product-serials', query: {
      'barcode': code.trim(),
      'page': 0,
      'size': 20,
    }) as Map<String, dynamic>;
    for (final row in json.listOf('data')) {
      final barcode = (row.stringOf('barcode') ?? '').trim().toLowerCase();
      final productId = row.intOf('productId');
      if (barcode == needle && productId != null) {
        for (final p in products) {
          if (p.id == productId) return p;
        }
      }
    }
  } on ApiException {
    // No permission or server error: fall through.
  }
  return null;
}
