import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/models.dart';
import '../catalog/repository.dart';
import '../sales/models.dart';

/// One product line in the POS cart.
class CartLine {
  const CartLine({
    required this.product,
    required this.qty,
    required this.price,
    this.itemDiscount = 0,
    this.serialIds = const [],
    this.serialLabels = const {},
    this.requiresSerial,
  });

  final Product product;
  final int qty;
  final double price;
  final double itemDiscount;

  /// Selected product-serial row ids (sent as `serialNumberIds`).
  final List<int> serialIds;

  /// id -> barcode, for display.
  final Map<int, String> serialLabels;

  /// null = unknown (serial rows not loaded yet); true = the product has
  /// serialised units in stock, so one serial per unit must be chosen.
  final bool? requiresSerial;

  double get subtotal => (price * qty - itemDiscount).clamp(0, double.infinity);
  bool get serialsComplete => requiresSerial != true || serialIds.length == qty;

  CartLine copyWith({
    int? qty,
    double? price,
    double? itemDiscount,
    List<int>? serialIds,
    Map<int, String>? serialLabels,
    bool? requiresSerial,
    bool clearRequiresSerial = false,
  }) =>
      CartLine(
        product: product,
        qty: qty ?? this.qty,
        price: price ?? this.price,
        itemDiscount: itemDiscount ?? this.itemDiscount,
        serialIds: serialIds ?? this.serialIds,
        serialLabels: serialLabels ?? this.serialLabels,
        requiresSerial: clearRequiresSerial ? null : (requiresSerial ?? this.requiresSerial),
      );
}

class CartState {
  const CartState({
    this.lines = const [],
    this.discount = 0,
    this.storeId,
    this.storeName,
    this.customer,
  });

  final List<CartLine> lines;

  /// Order-level discount in currency units (same as the web POS; tax is
  /// display-only on the web and not supported by the API, so omitted here).
  final double discount;
  final int? storeId;
  final String? storeName;
  final Customer? customer;

  int get totalItems => lines.fold(0, (a, l) => a + l.qty);
  double get subtotal => lines.fold(0.0, (a, l) => a + l.subtotal);
  double get grandTotal => (subtotal - discount).clamp(0, double.infinity);
  bool get isEmpty => lines.isEmpty;
  bool get serialsComplete => lines.every((l) => l.serialsComplete);

  int qtyOf(int productId) =>
      lines.where((l) => l.product.id == productId).fold(0, (a, l) => a + l.qty);

  CartState copyWith({
    List<CartLine>? lines,
    double? discount,
    int? storeId,
    String? storeName,
    Customer? customer,
    bool clearCustomer = false,
  }) =>
      CartState(
        lines: lines ?? this.lines,
        discount: discount ?? this.discount,
        storeId: storeId ?? this.storeId,
        storeName: storeName ?? this.storeName,
        customer: clearCustomer ? null : (customer ?? this.customer),
      );
}

class CartController extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  void setStore(int id, String name) {
    if (state.storeId == id) return;
    // Serials are store-specific: drop selections when the store changes.
    state = state.copyWith(
      storeId: id,
      storeName: name,
      lines: state.lines
          .map((l) => l.copyWith(serialIds: const [], serialLabels: const {}, clearRequiresSerial: true))
          .toList(),
    );
  }

  void setCustomer(Customer? customer) =>
      state = state.copyWith(customer: customer, clearCustomer: customer == null);

  void setDiscount(double value) =>
      state = state.copyWith(discount: value.clamp(0, state.subtotal));

  /// Adds one unit of [product]; loads its serial rows in the background to
  /// decide whether serial assignment is required.
  void add(Product product) {
    final index = state.lines.indexWhere((l) => l.product.id == product.id);
    if (index >= 0) {
      final line = state.lines[index];
      _replace(index, line.copyWith(qty: line.qty + 1));
    } else {
      state = state.copyWith(lines: [
        ...state.lines,
        CartLine(product: product, qty: 1, price: product.price),
      ]);
      _detectSerials(product.id);
    }
  }

  void setQty(int productId, int qty) {
    final index = state.lines.indexWhere((l) => l.product.id == productId);
    if (index < 0) return;
    if (qty <= 0) {
      remove(productId);
      return;
    }
    final line = state.lines[index];
    final serials = line.serialIds.length > qty ? line.serialIds.sublist(0, qty) : line.serialIds;
    _replace(index, line.copyWith(qty: qty, serialIds: serials));
  }

  void setPrice(int productId, double price) {
    final index = state.lines.indexWhere((l) => l.product.id == productId);
    if (index < 0) return;
    _replace(index, state.lines[index].copyWith(price: price.clamp(0, double.infinity)));
  }

  void setItemDiscount(int productId, double discount) {
    final index = state.lines.indexWhere((l) => l.product.id == productId);
    if (index < 0) return;
    _replace(index, state.lines[index].copyWith(itemDiscount: discount.clamp(0, double.infinity)));
  }

  void setSerials(int productId, List<int> ids, Map<int, String> labels) {
    final index = state.lines.indexWhere((l) => l.product.id == productId);
    if (index < 0) return;
    final line = state.lines[index];
    _replace(index, line.copyWith(serialIds: ids, serialLabels: labels, requiresSerial: true));
  }

  void remove(int productId) =>
      state = state.copyWith(lines: state.lines.where((l) => l.product.id != productId).toList());

  void clear() => state = CartState(storeId: state.storeId, storeName: state.storeName);

  void _replace(int index, CartLine line) {
    final lines = [...state.lines];
    lines[index] = line;
    state = state.copyWith(lines: lines);
  }

  Future<void> _detectSerials(int productId) async {
    try {
      final rows = await ref.read(catalogRepositoryProvider).serialsForProduct(productId);
      final available = availableSerials(rows, state.storeId);
      final requires = available.any((s) => s.isSerialised);
      final index = state.lines.indexWhere((l) => l.product.id == productId);
      if (index < 0) return;
      _replace(index, state.lines[index].copyWith(requiresSerial: requires));
    } catch (_) {
      // Leave as unknown; the cart shows it as optional.
    }
  }

  /// Serial rows that can be sold right now from [storeId]
  /// (status AVAILABLE, quantity > 0; see StockServiceImpl.findSerialById).
  static List<ProductSerial> availableSerials(List<ProductSerial> rows, int? storeId) {
    return rows.where((s) {
      if (!s.isAvailable) return false;
      if ((s.quantity ?? 0) <= 0) return false;
      if (storeId != null && s.storeId != null && s.storeId != storeId) return false;
      return true;
    }).toList();
  }

  /// Builds the backend request. [paidAmount] and [paymentMethod] come from
  /// the payment screen. The backend records the payment itself when
  /// `paidAmount > 0` (SaleServiceImpl.savePayment), so no second call to
  /// `/payments` is made.
  SaleRequest buildRequest({
    required int customerId,
    required double paidAmount,
    required String paymentMethod,
    int? bankId,
    String? note,
  }) {
    return SaleRequest(
      storeId: state.storeId ?? 1,
      customerId: customerId,
      discount: state.discount,
      paidAmount: paidAmount,
      paymentMethod: paymentMethod,
      bankId: bankId,
      noted: note,
      items: state.lines
          .map((l) => SaleItemRequest(
                productId: l.product.id,
                quantity: l.qty,
                price: l.price,
                itemDiscount: l.itemDiscount,
                serialNumberIds: l.serialIds,
              ))
          .toList(),
    );
  }
}

final cartProvider = NotifierProvider<CartController, CartState>(CartController.new);
