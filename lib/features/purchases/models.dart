import '../../core/utils/formatters.dart';
import '../catalog/models.dart';

/// dto/response/purchases/PurchaseResponse.java
class Purchase {
  const Purchase({
    required this.id,
    this.referenceNo,
    this.supplierId,
    this.supplierName,
    this.storeId,
    this.storeName,
    this.bankId,
    this.bankName,
    this.purchaseDate,
    this.total,
    this.discount,
    this.grandTotal,
    this.paidAmount,
    this.dueAmount,
    this.paymentStatus,
    this.status,
    this.note,
    this.items = const [],
  });

  final int id;
  final String? referenceNo;
  final int? supplierId;
  final String? supplierName;
  final int? storeId;
  final String? storeName;
  final int? bankId;
  final String? bankName;
  final String? purchaseDate;
  final double? total;
  final double? discount;
  final double? grandTotal;
  final double? paidAmount;
  final double? dueAmount;
  final String? paymentStatus;
  final String? status;
  final String? note;
  final List<PurchaseItem> items;

  double get due => dueAmount ?? ((grandTotal ?? 0) - (paidAmount ?? 0)).clamp(0, double.infinity);

  factory Purchase.fromJson(Map<String, dynamic> j) => Purchase(
        id: j.intOf('id') ?? 0,
        referenceNo: j.stringOf('referenceNo'),
        supplierId: j.intOf('supplierId'),
        supplierName: j.stringOf('supplierName'),
        storeId: j.intOf('storeId'),
        storeName: j.stringOf('storeName'),
        bankId: j.intOf('bankId'),
        bankName: j.stringOf('bankName'),
        purchaseDate: j.stringOf('purchaseDate'),
        total: j.doubleOf('total'),
        discount: j.doubleOf('discount'),
        grandTotal: j.doubleOf('grandTotal'),
        paidAmount: j.doubleOf('paidAmount'),
        dueAmount: j.doubleOf('dueAmount'),
        paymentStatus: j.stringOf('paymentStatus'),
        status: j.stringOf('status'),
        note: j.stringOf('note'),
        items: j.listOf('items').map(PurchaseItem.fromJson).toList(),
      );
}

class PurchaseItem {
  const PurchaseItem({
    required this.id,
    this.productId,
    this.productName,
    this.quantity,
    this.cost,
    this.price,
    this.subtotal,
    this.serialNumbers = const [],
  });

  final int id;
  final int? productId;
  final String? productName;
  final double? quantity;
  final double? cost;
  final double? price;
  final double? subtotal;
  final List<ProductSerial> serialNumbers;

  factory PurchaseItem.fromJson(Map<String, dynamic> j) => PurchaseItem(
        id: j.intOf('id') ?? 0,
        productId: j.intOf('productId'),
        productName: j.stringOf('productName'),
        quantity: j.doubleOf('quantity'),
        cost: j.doubleOf('cost'),
        price: j.doubleOf('price'),
        subtotal: j.doubleOf('subtotal'),
        serialNumbers: j.listOf('serialNumbers').map(ProductSerial.fromJson).toList(),
      );
}

/// dto/request/purchases/PurchaseRequest.java
class PurchaseRequest {
  const PurchaseRequest({
    required this.supplierId,
    required this.storeId,
    required this.bankId,
    required this.purchaseDate,
    this.discount,
    this.paidAmount,
    this.note,
    required this.items,
  });

  final int supplierId;
  final int storeId;
  final int bankId;
  final DateTime purchaseDate;
  final double? discount;
  final double? paidAmount;
  final String? note;
  final List<PurchaseItemRequest> items;

  Map<String, dynamic> toJson() => {
        'supplierId': supplierId,
        'storeId': storeId,
        'bankId': bankId,
        'purchaseDate': Fmt.apiDate(purchaseDate),
        'discount': discount ?? 0,
        'paidAmount': paidAmount ?? 0,
        if (note != null && note!.isNotEmpty) 'note': note,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

class PurchaseItemRequest {
  const PurchaseItemRequest({
    required this.productId,
    required this.quantity,
    this.cost,
    this.price,
    this.serialNumbers,
  });

  final int productId;
  final num quantity;
  final double? cost;
  final double? price;
  final List<String>? serialNumbers;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'quantity': quantity,
        if (cost != null) 'cost': cost,
        if (price != null) 'price': price,
        if (serialNumbers != null && serialNumbers!.isNotEmpty) 'serialNumbers': serialNumbers,
      };
}

class Supplier {
  const Supplier({
    required this.id,
    this.code,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.country,
    this.note,
    this.status,
  });

  final int id;
  final String? code;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? country;
  final String? note;
  final String? status;

  factory Supplier.fromJson(Map<String, dynamic> j) => Supplier(
        id: j.intOf('id') ?? 0,
        code: j.stringOf('code'),
        name: j.stringOf('name') ?? '',
        phone: j.stringOf('phone'),
        email: j.stringOf('email'),
        address: j.stringOf('address'),
        city: j.stringOf('city'),
        country: j.stringOf('country'),
        note: j.stringOf('note'),
        status: j.stringOf('status'),
      );
}

class SupplierRequest {
  const SupplierRequest({
    required this.code,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.country,
    this.note,
    this.status = 'ACT',
  });

  final String code;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? country;
  final String? note;
  final String status;

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'city': city,
        'country': country,
        'note': note,
        'status': status,
      };
}

class Expense {
  const Expense({
    required this.id,
    this.reference,
    this.amount,
    this.note,
    this.storeId,
    this.storeName,
    this.bankId,
    this.bankName,
    this.expenseTypeId,
    this.expenseTypeName,
    this.status,
    this.createdAt,
    this.createdBy,
  });

  final int id;
  final String? reference;
  final double? amount;
  final String? note;
  final int? storeId;
  final String? storeName;
  final int? bankId;
  final String? bankName;
  final int? expenseTypeId;
  final String? expenseTypeName;
  final String? status;
  final String? createdAt;
  final String? createdBy;

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j.intOf('id') ?? 0,
        reference: j.stringOf('reference'),
        amount: j.doubleOf('amount'),
        note: j.stringOf('note'),
        storeId: j.intOf('storeId'),
        storeName: j.stringOf('storeName'),
        bankId: j.intOf('bankId'),
        bankName: j.stringOf('bankName'),
        expenseTypeId: j.intOf('expenseTypeId'),
        expenseTypeName: j.stringOf('expenseTypeName'),
        status: j.stringOf('status'),
        createdAt: j.stringOf('createdAt'),
        createdBy: j.stringOf('createdBy'),
      );
}

class ExpenseRequest {
  const ExpenseRequest({
    required this.reference,
    required this.amount,
    this.note,
    required this.storeId,
    this.bankId,
    required this.expenseTypeId,
    this.status = 'ACT',
  });

  final String reference;
  final double amount;
  final String? note;
  final int storeId;
  final int? bankId;
  final int expenseTypeId;
  final String status;

  Map<String, dynamic> toJson() => {
        'reference': reference,
        'amount': amount,
        'note': note,
        'storeId': storeId,
        if (bankId != null) 'bankId': bankId,
        'expenseTypeId': expenseTypeId,
        'status': status,
      };
}

class ExpenseType {
  const ExpenseType({required this.id, this.code, required this.name, this.description, this.status});
  final int id;
  final String? code;
  final String name;
  final String? description;
  final String? status;

  factory ExpenseType.fromJson(Map<String, dynamic> j) => ExpenseType(
        id: j.intOf('id') ?? 0,
        code: j.stringOf('code'),
        name: j.stringOf('name') ?? '',
        description: j.stringOf('description'),
        status: j.stringOf('status'),
      );
}
