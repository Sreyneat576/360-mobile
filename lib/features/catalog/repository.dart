import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/paged.dart';
import 'models.dart';

/// Catalog endpoints (see docs/MOBILE_APP_ANALYSIS.md for the backend quirks
/// handled here: product `name`/`code` filters are exact-match, so search is
/// done client-side; `product-serial?barcode=` throws on the server, so the
/// serial list is filtered by `productId` and matched locally).
class CatalogRepository {
  CatalogRepository(this._api);

  final ApiClient _api;

  Future<Paged<Product>> products({
    int page = 1,
    int size = 50,
    int? categoryId,
    int? brandId,
    int? modelId,
    String? status,
  }) async {
    final json = await _api.get('/product', query: {
      'page': page,
      'size': size,
      'categoryId': categoryId,
      'brandId': brandId,
      'modelId': modelId,
      'status': status,
    });
    return Paged.fromJson(json as Map<String, dynamic>, Product.fromJson);
  }

  /// Loads every active product (paged under the hood) so the POS can search
  /// by name or code locally. Capped to avoid runaway loops.
  Future<List<Product>> allProducts({int? categoryId, int pageSize = 100}) async {
    final all = <Product>[];
    var page = 1;
    while (page <= 20) {
      final result = await products(page: page, size: pageSize, categoryId: categoryId);
      all.addAll(result.data);
      if (!result.hasMore || result.data.isEmpty) break;
      page++;
    }
    return all;
  }

  Future<Product> product(int id) async {
    final json = await _api.get('/product/$id');
    return Product.fromJson(json as Map<String, dynamic>);
  }

  Future<ProductDetail> productDetail(int id) async {
    final json = await _api.get('/product/$id/detail');
    return ProductDetail.fromJson(json as Map<String, dynamic>);
  }

  Future<Product> createProduct(ProductRequest request) async {
    final json = await _api.post('/product', body: request.toJson());
    return Product.fromJson(json as Map<String, dynamic>);
  }

  Future<Product> updateProduct(int id, ProductRequest request) async {
    final json = await _api.put('/product/$id', body: request.toJson());
    return Product.fromJson(json as Map<String, dynamic>);
  }

  Future<void> deleteProduct(int id) => _api.delete('/product/$id');

  /// Serial rows for one product (all stores, all statuses; the backend has
  /// no working store/status filter on this endpoint).
  Future<List<ProductSerial>> serialsForProduct(int productId) async {
    final all = <ProductSerial>[];
    var page = 1;
    while (page <= 10) {
      final json = await _api.get('/product-serial', query: {
        'productId': productId,
        'page': page,
        'size': 100,
      });
      final result = Paged.fromJson(json as Map<String, dynamic>, ProductSerial.fromJson);
      all.addAll(result.data);
      if (!result.hasMore || result.data.isEmpty) break;
      page++;
    }
    return all;
  }

  Future<Paged<ProductSerial>> serials({int page = 1, int size = 20, int? productId}) async {
    final json = await _api.get('/product-serial', query: {
      'page': page,
      'size': size,
      'productId': productId,
    });
    return Paged.fromJson(json as Map<String, dynamic>, ProductSerial.fromJson);
  }

  Future<List<Category>> categories() async {
    final json = await _api.get('/category', query: {'page': 1, 'size': 200});
    return Paged.fromJson(json as Map<String, dynamic>, Category.fromJson).data;
  }

  Future<List<Brand>> brands() async {
    final json = await _api.get('/brand', query: {'page': 1, 'size': 200});
    return Paged.fromJson(json as Map<String, dynamic>, Brand.fromJson).data;
  }

  Future<List<ProductModel>> models() async {
    final json = await _api.get('/model', query: {'page': 1, 'size': 500});
    return Paged.fromJson(json as Map<String, dynamic>, ProductModel.fromJson).data;
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient.instance);

final catalogRepositoryProvider =
    Provider<CatalogRepository>((ref) => CatalogRepository(ref.watch(apiClientProvider)));

final categoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(catalogRepositoryProvider).categories(),
);

final brandsProvider = FutureProvider<List<Brand>>(
  (ref) => ref.watch(catalogRepositoryProvider).brands(),
);

final modelsProvider = FutureProvider<List<ProductModel>>(
  (ref) => ref.watch(catalogRepositoryProvider).models(),
);

final productDetailProvider = FutureProvider.family<ProductDetail, int>(
  (ref, id) => ref.watch(catalogRepositoryProvider).productDetail(id),
);

final productSerialsProvider = FutureProvider.family<List<ProductSerial>, int>(
  (ref, productId) => ref.watch(catalogRepositoryProvider).serialsForProduct(productId),
);
