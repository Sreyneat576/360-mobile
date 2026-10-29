import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/paged.dart';
import '../catalog/repository.dart';
import 'models.dart';

class SalesRepository {
  SalesRepository(this._api);
  final ApiClient _api;

  Future<Paged<Sale>> sales({
    int page = 1,
    int size = 20,
    String? status,
    int? customerId,
  }) async {
    final json = await _api.get('/sales', query: {
      'page': page,
      'size': size,
      'status': status,
      'customerId': customerId,
    });
    return Paged.fromJson(json as Map<String, dynamic>, Sale.fromJson);
  }

  Future<Sale> sale(int id) async {
    final json = await _api.get('/sales/$id');
    return Sale.fromJson(json as Map<String, dynamic>);
  }

  Future<Sale> create(SaleRequest request) async {
    final json = await _api.post('/sales', body: request.toJson());
    return Sale.fromJson(json as Map<String, dynamic>);
  }

  Future<Sale> cancel(int id) async {
    final json = await _api.patch('/sales/$id/cancel');
    return Sale.fromJson(json as Map<String, dynamic>);
  }

  Future<Sale> complete(int id) async {
    final json = await _api.patch('/sales/$id/complete');
    return Sale.fromJson(json as Map<String, dynamic>);
  }

  Future<Sale> returnSale(int id, List<SaleReturnItemRequest> items) async {
    final json = await _api.patch('/sales/$id/return', body: {
      'items': items.map((e) => e.toJson()).toList(),
    });
    return Sale.fromJson(json as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _api.delete('/sales/$id');

  // ---------------------------------------------------------------------------
  // Payments
  // ---------------------------------------------------------------------------

  Future<Paged<Payment>> payments({
    int page = 1,
    int size = 20,
    int? saleId,
    String? paymentNo,
    int? bankId,
  }) async {
    final json = await _api.get('/payments', query: {
      'page': page,
      'size': size,
      'saleId': saleId,
      'paymentNo': paymentNo,
      'bankId': bankId,
    });
    return Paged.fromJson(json as Map<String, dynamic>, Payment.fromJson);
  }

  Future<Payment> createPayment(PaymentRequest request) async {
    final json = await _api.post('/payments', body: request.toJson());
    return Payment.fromJson(json as Map<String, dynamic>);
  }

  Future<void> deletePayment(int id) => _api.delete('/payments/$id');

  // ---------------------------------------------------------------------------
  // Customers
  // ---------------------------------------------------------------------------

  Future<Paged<Customer>> customers({int page = 1, int size = 50, String? name, String? code}) async {
    final json = await _api.get('/customer', query: {
      'page': page,
      'size': size,
      'name': name,
      'code': code,
    });
    return Paged.fromJson(json as Map<String, dynamic>, Customer.fromJson);
  }

  Future<List<Customer>> allCustomers() async {
    final all = <Customer>[];
    var page = 1;
    while (page <= 20) {
      final result = await customers(page: page, size: 100);
      all.addAll(result.data);
      if (!result.hasMore || result.data.isEmpty) break;
      page++;
    }
    return all;
  }

  Future<Customer> createCustomer(CustomerRequest request) async {
    final json = await _api.post('/customer', body: request.toJson());
    return Customer.fromJson(json as Map<String, dynamic>);
  }

  Future<Customer> updateCustomer(int id, CustomerRequest request) async {
    final json = await _api.put('/customer/$id', body: request.toJson());
    return Customer.fromJson(json as Map<String, dynamic>);
  }

  Future<void> deleteCustomer(int id) => _api.delete('/customer/$id');

  /// The backend requires a customer on every sale (a null `customerId`
  /// fails with 500), so the POS falls back to a "Walk-In Customer" record,
  /// creating it on first use. Mirrors the web POS default.
  static const walkInName = 'Walk-In Customer';
  static const walkInCode = 'WALK-IN';

  Future<Customer> walkInCustomer() async {
    final found = await customers(page: 1, size: 5, name: walkInName);
    for (final c in found.data) {
      if (c.name.trim().toLowerCase() == walkInName.toLowerCase()) return c;
    }
    final byCode = await customers(page: 1, size: 5, code: walkInCode);
    if (byCode.data.isNotEmpty) return byCode.data.first;
    return createCustomer(const CustomerRequest(code: walkInCode, name: walkInName));
  }

  // ---------------------------------------------------------------------------
  // Quotes
  // ---------------------------------------------------------------------------

  Future<Paged<Quote>> quotes({int page = 1, int size = 20, int? customerId, String? reference}) async {
    final json = await _api.get('/quote', query: {
      'page': page,
      'size': size,
      'customerId': customerId,
      'reference': reference,
    });
    return Paged.fromJson(json as Map<String, dynamic>, Quote.fromJson);
  }

  Future<Quote> quote(int id) async {
    final json = await _api.get('/quote/$id');
    return Quote.fromJson(json as Map<String, dynamic>);
  }

  Future<Quote> createQuote(QuoteRequest request) async {
    final json = await _api.post('/quote', body: request.toJson());
    return Quote.fromJson(json as Map<String, dynamic>);
  }

  Future<void> deleteQuote(int id) => _api.delete('/quote/$id');
}

final salesRepositoryProvider = Provider<SalesRepository>(
  (ref) => SalesRepository(ref.watch(apiClientProvider)),
);

final saleDetailProvider = FutureProvider.family<Sale, int>(
  (ref, id) => ref.watch(salesRepositoryProvider).sale(id),
);

final salePaymentsProvider = FutureProvider.family<List<Payment>, int>(
  (ref, saleId) async =>
      (await ref.watch(salesRepositoryProvider).payments(saleId: saleId, size: 100)).data,
);

final customersProvider = FutureProvider<List<Customer>>(
  (ref) => ref.watch(salesRepositoryProvider).allCustomers(),
);

final quoteDetailProvider = FutureProvider.family<Quote, int>(
  (ref, id) => ref.watch(salesRepositoryProvider).quote(id),
);
