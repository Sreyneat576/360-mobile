import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/paged.dart';
import '../catalog/repository.dart';
import 'models.dart';

class PurchasesRepository {
  PurchasesRepository(this._api);
  final ApiClient _api;

  /// Purchases list. `supplierId`/`storeId` filters crash the backend, so
  /// only text/status filters are sent and the rest is filtered locally.
  Future<Paged<Purchase>> purchases({
    int page = 1,
    int size = 20,
    String? referenceNo,
    String? status,
    String? paymentStatus,
  }) async {
    final json = await _api.get('/purchases', query: {
      'page': page,
      'size': size,
      'referenceNo': referenceNo,
      'status': status,
      'paymentStatus': paymentStatus,
    });
    return Paged.fromJson(json as Map<String, dynamic>, Purchase.fromJson);
  }

  Future<Purchase> purchase(int id) async {
    final json = await _api.get('/purchases/$id');
    return Purchase.fromJson(json as Map<String, dynamic>);
  }

  Future<Purchase> createPurchase(PurchaseRequest request) async {
    final json = await _api.post('/purchases', body: request.toJson());
    return Purchase.fromJson(json as Map<String, dynamic>);
  }

  /// DELETE cancels the purchase and reverses its stock.
  Future<void> cancelPurchase(int id) => _api.delete('/purchases/$id');

  Future<Paged<Supplier>> suppliers({int page = 1, int size = 50, String? name}) async {
    final json = await _api.get('/suppliers', query: {'page': page, 'size': size, 'name': name});
    return Paged.fromJson(json as Map<String, dynamic>, Supplier.fromJson);
  }

  Future<List<Supplier>> allSuppliers() async {
    final all = <Supplier>[];
    var page = 1;
    while (page <= 10) {
      final r = await suppliers(page: page, size: 100);
      all.addAll(r.data);
      if (!r.hasMore || r.data.isEmpty) break;
      page++;
    }
    return all;
  }

  Future<Supplier> createSupplier(SupplierRequest request) async {
    final json = await _api.post('/suppliers', body: request.toJson());
    return Supplier.fromJson(json as Map<String, dynamic>);
  }

  Future<Supplier> updateSupplier(int id, SupplierRequest request) async {
    final json = await _api.put('/suppliers/$id', body: request.toJson());
    return Supplier.fromJson(json as Map<String, dynamic>);
  }

  Future<void> deleteSupplier(int id) => _api.delete('/suppliers/$id');

  Future<Paged<Expense>> expenses({int page = 1, int size = 20, String? reference}) async {
    final json = await _api.get('/expenses', query: {
      'page': page,
      'size': size,
      'reference': reference,
    });
    return Paged.fromJson(json as Map<String, dynamic>, Expense.fromJson);
  }

  Future<Expense> createExpense(ExpenseRequest request) async {
    final json = await _api.post('/expenses', body: request.toJson());
    return Expense.fromJson(json as Map<String, dynamic>);
  }

  Future<Expense> updateExpense(int id, ExpenseRequest request) async {
    final json = await _api.put('/expenses/$id', body: request.toJson());
    return Expense.fromJson(json as Map<String, dynamic>);
  }

  Future<void> deleteExpense(int id) => _api.delete('/expenses/$id');

  Future<List<ExpenseType>> expenseTypes() async {
    final json = await _api.get('/expense-types', query: {'page': 1, 'size': 200});
    return Paged.fromJson(json as Map<String, dynamic>, ExpenseType.fromJson).data;
  }
}

final purchasesRepositoryProvider = Provider<PurchasesRepository>(
  (ref) => PurchasesRepository(ref.watch(apiClientProvider)),
);

final suppliersProvider = FutureProvider<List<Supplier>>(
  (ref) => ref.watch(purchasesRepositoryProvider).allSuppliers(),
);

final expenseTypesProvider = FutureProvider<List<ExpenseType>>(
  (ref) => ref.watch(purchasesRepositoryProvider).expenseTypes(),
);

final purchaseDetailProvider = FutureProvider.family<Purchase, int>(
  (ref, id) => ref.watch(purchasesRepositoryProvider).purchase(id),
);
