import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/paged.dart';
import '../catalog/repository.dart';
import 'models.dart';

class FinanceRepository {
  FinanceRepository(this._api);
  final ApiClient _api;

  Future<List<Bank>> banks() async {
    final json = await _api.get('/bank', query: {'page': 1, 'size': 100});
    return Paged.fromJson(json as Map<String, dynamic>, Bank.fromJson).data;
  }

  Future<Bank> createBank(BankRequest request) async {
    final json = await _api.post('/bank', body: request.toJson());
    return Bank.fromJson(json as Map<String, dynamic>);
  }

  Future<Bank> updateBank(int id, BankRequest request) async {
    final json = await _api.put('/bank/$id', body: request.toJson());
    return Bank.fromJson(json as Map<String, dynamic>);
  }

  Future<void> deleteBank(int id) => _api.delete('/bank/$id');

  /// Note: `currency:*` permissions are not seeded by the backend, so this
  /// returns 403 for every default role until an admin creates them.
  Future<List<Currency>> currencies() async {
    final json = await _api.get('/currency', query: {'page': 1, 'size': 100});
    return Paged.fromJson(json as Map<String, dynamic>, Currency.fromJson).data;
  }

  Future<Currency> createCurrency(CurrencyRequest request) async {
    final json = await _api.post('/currency', body: request.toJson());
    return Currency.fromJson(json as Map<String, dynamic>);
  }

  Future<Currency> updateCurrency(int id, CurrencyRequest request) async {
    final json = await _api.put('/currency/$id', body: request.toJson());
    return Currency.fromJson(json as Map<String, dynamic>);
  }

  Future<void> deleteCurrency(int id) => _api.delete('/currency/$id');
}

final financeRepositoryProvider = Provider<FinanceRepository>(
  (ref) => FinanceRepository(ref.watch(apiClientProvider)),
);

final banksProvider = FutureProvider<List<Bank>>(
  (ref) => ref.watch(financeRepositoryProvider).banks(),
);

final currenciesProvider = FutureProvider<List<Currency>>(
  (ref) => ref.watch(financeRepositoryProvider).currencies(),
);
