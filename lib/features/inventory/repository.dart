import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/paged.dart';
import '../catalog/repository.dart';
import 'models.dart';

class InventoryRepository {
  InventoryRepository(this._api);

  final ApiClient _api;

  /// Stock rows. The backend's `status` filter is a no-op, so callers filter
  /// by [StockRow.level] client-side.
  Future<Paged<StockRow>> stock({
    int page = 1,
    int size = 50,
    int? storeId,
    int? productId,
  }) async {
    final json = await _api.get('/stock', query: {
      'page': page,
      'size': size,
      'storeId': storeId,
      'productId': productId,
    });
    return Paged.fromJson(json as Map<String, dynamic>, StockRow.fromJson);
  }

  /// All stock rows (optionally for one store), paged under the hood.
  Future<List<StockRow>> allStock({int? storeId}) async {
    final all = <StockRow>[];
    var page = 1;
    while (page <= 20) {
      final result = await stock(page: page, size: 100, storeId: storeId);
      all.addAll(result.data);
      if (!result.hasMore || result.data.isEmpty) break;
      page++;
    }
    return all;
  }

  Future<List<Store>> stores() async {
    final json = await _api.get('/stores', query: {'page': 1, 'size': 100});
    return Paged.fromJson(json as Map<String, dynamic>, Store.fromJson).data;
  }

  Future<Store> store(int id) async {
    final json = await _api.get('/stores/$id');
    return Store.fromJson(json as Map<String, dynamic>);
  }

  Future<Store> createStore(StoreRequest request) async {
    final json = await _api.post('/stores', body: request.toJson());
    return Store.fromJson(json as Map<String, dynamic>);
  }

  Future<Store> updateStore(int id, StoreRequest request) async {
    final json = await _api.put('/stores/$id', body: request.toJson());
    return Store.fromJson(json as Map<String, dynamic>);
  }

  Future<void> deleteStore(int id) => _api.delete('/stores/$id');
}

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => InventoryRepository(ref.watch(apiClientProvider)),
);

final storesProvider = FutureProvider<List<Store>>(
  (ref) => ref.watch(inventoryRepositoryProvider).stores(),
);

/// Stock rows for a store (null = all stores).
final stockProvider = FutureProvider.family<List<StockRow>, int?>(
  (ref, storeId) => ref.watch(inventoryRepositoryProvider).allStock(storeId: storeId),
);
