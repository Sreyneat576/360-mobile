import '../../core/utils/formatters.dart';

/// dto/response/inventory/StockResponse.java
///
/// Note: the backend's StockMapper fills `productId`/`productName` from the
/// product's *model*, so `productId` here cannot be used to look a product up.
class StockRow {
  const StockRow({
    required this.id,
    this.productId,
    this.productName,
    this.storeId,
    this.storeName,
    this.quantity,
    this.alertQuantity,
    this.reorderLevel,
    this.status,
  });

  final int id;
  final int? productId;
  final String? productName;
  final int? storeId;
  final String? storeName;
  final double? quantity;
  final double? alertQuantity;
  final int? reorderLevel;

  /// `IN_STOCK`, `LOW_STOCK` or `OUT_STOCK` (computed by the backend).
  final String? status;

  double get qty => quantity ?? 0;
  double get alert => (alertQuantity ?? 0) > 0
      ? alertQuantity!
      : (reorderLevel ?? 0).toDouble();

  StockLevel get level {
    switch ((status ?? '').toUpperCase()) {
      case 'OUT_STOCK':
      case 'OUT_OF_STOCK':
        return StockLevel.out;
      case 'LOW_STOCK':
        return StockLevel.low;
      case 'IN_STOCK':
        return StockLevel.inStock;
    }
    if (qty <= 0) return StockLevel.out;
    if (alert > 0 && qty <= alert) return StockLevel.low;
    return StockLevel.inStock;
  }

  factory StockRow.fromJson(Map<String, dynamic> j) => StockRow(
        id: j.intOf('id') ?? 0,
        productId: j.intOf('productId'),
        productName: j.stringOf('productName'),
        storeId: j.intOf('storeId'),
        storeName: j.stringOf('storeName'),
        quantity: j.doubleOf('quantity'),
        alertQuantity: j.doubleOf('alertQuantity'),
        reorderLevel: j.intOf('reorderLevel'),
        status: j.stringOf('status'),
      );
}

enum StockLevel { inStock, low, out }

/// dto/response/inventory/StoreResponse.java
class Store {
  const Store({
    required this.id,
    required this.name,
    this.code,
    this.logo,
    this.email,
    this.phone,
    this.city,
    this.state,
    this.country,
    this.receiptHeader,
    this.receiptFooter,
    this.status,
  });

  final int id;
  final String name;
  final String? code;
  final String? logo;
  final String? email;
  final String? phone;
  final String? city;
  final String? state;
  final String? country;
  final String? receiptHeader;
  final String? receiptFooter;
  final String? status;

  factory Store.fromJson(Map<String, dynamic> j) => Store(
        id: j.intOf('id') ?? 0,
        name: j.stringOf('name') ?? '',
        code: j.stringOf('code'),
        logo: j.stringOf('logo'),
        email: j.stringOf('email'),
        phone: j.stringOf('phone'),
        city: j.stringOf('city'),
        state: j.stringOf('state'),
        country: j.stringOf('country'),
        receiptHeader: j.stringOf('receiptHeader'),
        receiptFooter: j.stringOf('receiptFooter'),
        status: j.stringOf('status'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'logo': logo,
        'email': email,
        'phone': phone,
        'city': city,
        'state': state,
        'country': country,
        'receiptHeader': receiptHeader,
        'receiptFooter': receiptFooter,
        'status': status,
      };
}

class StoreRequest {
  const StoreRequest({
    required this.name,
    required this.code,
    this.logo,
    this.email,
    required this.phone,
    this.city,
    this.state,
    this.country,
    this.receiptHeader,
    this.receiptFooter,
    this.status,
  });

  final String name;
  final String code;
  final String? logo;
  final String? email;
  final String phone;
  final String? city;
  final String? state;
  final String? country;
  final String? receiptHeader;
  final String? receiptFooter;
  final String? status;

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'logo': logo,
        'email': email,
        'phone': phone,
        'city': city,
        'state': state,
        'country': country,
        'receiptHeader': receiptHeader,
        'receiptFooter': receiptFooter,
        'status': status,
      };
}
