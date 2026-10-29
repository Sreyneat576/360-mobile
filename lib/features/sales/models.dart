import '../../core/utils/formatters.dart';
import '../catalog/models.dart';

/// Sale status values (Constants.java).
class SaleStatus {
  SaleStatus._();
  static const completed = 'COMPLETED';
  static const pending = 'PENDING';
  static const cancelled = 'CANCELLED';
  static const returned = 'RETURNED';
  static const partiallyReturned = 'PARTIALLY_RETURNED';
}

class PaymentStatus {
  PaymentStatus._();
  static const pending = 'PENDING';
  static const partial = 'PARTIAL';
  static const paid = 'PAID';
}

/// Client-side convention for `paymentMethod` (free text on the backend).
class PaymentMethod {
  PaymentMethod._();
  static const cash = 'CASH';
  static const bank = 'BANK';
}

/// dto/response/sales/SaleResponse.java
class Sale {
  const Sale({
    required this.id,
    this.date,
    this.reference,
    this.no,
    this.storeId,
    this.storeName,
    this.bankId,
    this.bankName,
    this.customerId,
    this.customerName,
    this.userId,
    this.userName,
    this.grandTotal,
    this.discount,
    this.status,
    this.paymentStatus,
    this.paidAmount,
    this.returnAmount,
    this.noted,
    this.items = const [],
    this.createdAt,
    this.createdBy,
  });

  final int id;
  final String? date;
  final String? reference;
  final String? no;
  final int? storeId;
  final String? storeName;
  final int? bankId;
  final String? bankName;
  final int? customerId;
  final String? customerName;
  final int? userId;
  final String? userName;
  final double? grandTotal;
  final double? discount;

  /// Sale status (`saleStatus` on the entity).
  final String? status;
  final String? paymentStatus;
  final double? paidAmount;
  final double? returnAmount;
  final String? noted;
  final List<SaleItem> items;
  final String? createdAt;
  final String? createdBy;

  double get total => grandTotal ?? 0;
  double get paid => paidAmount ?? 0;
  double get due => (total - paid).clamp(0, double.infinity);
  String get displayNo => (no?.isNotEmpty ?? false) ? no! : (reference ?? 'POS-$id');
  bool get isCompleted => status == SaleStatus.completed;
  bool get canReturn =>
      status == SaleStatus.completed || status == SaleStatus.partiallyReturned;

  factory Sale.fromJson(Map<String, dynamic> j) => Sale(
        id: j.intOf('id') ?? 0,
        date: j.stringOf('date'),
        reference: j.stringOf('reference'),
        no: j.stringOf('no'),
        storeId: j.intOf('storeId'),
        storeName: j.stringOf('storeName'),
        bankId: j.intOf('bankId'),
        bankName: j.stringOf('bankName'),
        customerId: j.intOf('customerId'),
        customerName: j.stringOf('customerName'),
        userId: j.intOf('userId'),
        userName: j.stringOf('userName'),
        grandTotal: j.doubleOf('grandTotal'),
        discount: j.doubleOf('discount'),
        status: j.stringOf('status'),
        paymentStatus: j.stringOf('paymentStatus'),
        paidAmount: j.doubleOf('paidAmount'),
        returnAmount: j.doubleOf('returnAmount'),
        noted: j.stringOf('noted'),
        items: j.listOf('items').map(SaleItem.fromJson).toList(),
        createdAt: j.stringOf('createdAt'),
        createdBy: j.stringOf('createdBy'),
      );
}

/// dto/response/sales/SaleItemResponse.java
class SaleItem {
  const SaleItem({
    required this.id,
    this.productId,
    this.productName,
    this.qty,
    this.price,
    this.itemDiscount,
    this.subTotal,
    this.productSerialIds = const [],
    this.serialNumbers = const [],
    this.serials = const [],
  });

  final int id;
  final int? productId;
  final String? productName;
  final int? qty;
  final double? price;
  final double? itemDiscount;
  final double? subTotal;
  final List<int> productSerialIds;
  final List<String> serialNumbers;
  final List<ProductSerial> serials;

  bool get isSerialised => productSerialIds.isNotEmpty;

  factory SaleItem.fromJson(Map<String, dynamic> j) => SaleItem(
        id: j.intOf('id') ?? 0,
        productId: j.intOf('productId'),
        productName: j.stringOf('productName'),
        qty: j.intOf('qty'),
        price: j.doubleOf('price'),
        itemDiscount: j.doubleOf('itemDiscount'),
        subTotal: j.doubleOf('subTotal'),
        productSerialIds: j.intListOf('productSerialIds'),
        serialNumbers: j.stringListOf('serialNumbers'),
        serials: j.listOf('serials').map(ProductSerial.fromJson).toList(),
      );
}

/// dto/request/sales/SaleRequest.java
class SaleRequest {
  const SaleRequest({
    this.reference,
    required this.storeId,
    required this.customerId,
    this.discount,
    this.paymentMethod,
    this.bankId,
    this.paidAmount,
    this.noted,
    required this.items,
  });

  final String? reference;
  final int storeId;
  final int customerId;
  final double? discount;
  final String? paymentMethod;
  final int? bankId;
  final double? paidAmount;
  final String? noted;
  final List<SaleItemRequest> items;

  Map<String, dynamic> toJson() => {
        if (reference != null) 'reference': reference,
        'storeId': storeId,
        'customerId': customerId,
        'discount': discount ?? 0,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (bankId != null) 'bankId': bankId,
        'paidAmount': paidAmount ?? 0,
        if (noted != null && noted!.isNotEmpty) 'noted': noted,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

class SaleItemRequest {
  const SaleItemRequest({
    required this.productId,
    required this.quantity,
    required this.price,
    this.itemDiscount,
    this.serialNumberIds,
  });

  final int productId;
  final num quantity;
  final double price;
  final double? itemDiscount;
  final List<int>? serialNumberIds;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'quantity': quantity,
        'price': price,
        'itemDiscount': itemDiscount ?? 0,
        if (serialNumberIds != null && serialNumberIds!.isNotEmpty)
          'serialNumberIds': serialNumberIds,
      };
}

class SaleReturnItemRequest {
  const SaleReturnItemRequest({
    required this.saleItemId,
    required this.quantity,
    this.serialNumberIds,
  });

  final int saleItemId;
  final num quantity;
  final List<int>? serialNumberIds;

  Map<String, dynamic> toJson() => {
        'saleItemId': saleItemId,
        'quantity': quantity,
        if (serialNumberIds != null && serialNumberIds!.isNotEmpty)
          'serialNumberIds': serialNumberIds,
      };
}

/// dto/response/sales/PaymentResponse.java
class Payment {
  const Payment({
    required this.id,
    this.paymentNo,
    this.paymentMethod,
    this.bankId,
    this.bankName,
    this.amount,
    this.transactionNo,
    this.status,
    this.paymentDate,
    this.saleId,
    this.saleNo,
    this.purchaseId,
    this.userId,
    this.userName,
    this.createdAt,
  });

  final int id;
  final String? paymentNo;
  final String? paymentMethod;
  final int? bankId;
  final String? bankName;
  final double? amount;
  final String? transactionNo;
  final String? status;
  final String? paymentDate;
  final int? saleId;
  final String? saleNo;
  final int? purchaseId;
  final int? userId;
  final String? userName;
  final String? createdAt;

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        id: j.intOf('id') ?? 0,
        paymentNo: j.stringOf('paymentNo'),
        paymentMethod: j.stringOf('paymentMethod'),
        bankId: j.intOf('bankId'),
        bankName: j.stringOf('bankName'),
        amount: j.doubleOf('amount'),
        transactionNo: j.stringOf('transactionNo'),
        status: j.stringOf('status'),
        paymentDate: j.stringOf('paymentDate'),
        saleId: j.intOf('saleId'),
        saleNo: j.stringOf('saleNo'),
        purchaseId: j.intOf('purchaseId'),
        userId: j.intOf('userId'),
        userName: j.stringOf('userName'),
        createdAt: j.stringOf('createdAt'),
      );
}

/// dto/request/sales/PaymentRequest.java
class PaymentRequest {
  const PaymentRequest({
    this.saleId,
    this.purchaseId,
    required this.amount,
    this.paymentMethod,
    this.bankId,
    this.transactionNo,
    this.paymentDate,
  });

  final int? saleId;
  final int? purchaseId;
  final double amount;
  final String? paymentMethod;
  final int? bankId;
  final String? transactionNo;
  final DateTime? paymentDate;

  Map<String, dynamic> toJson() => {
        if (saleId != null) 'saleId': saleId,
        if (purchaseId != null) 'purchaseId': purchaseId,
        'amount': amount,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (bankId != null) 'bankId': bankId,
        if (transactionNo != null && transactionNo!.isNotEmpty) 'transactionNo': transactionNo,
        if (paymentDate != null) 'paymentDate': Fmt.apiDateTime(paymentDate!),
      };
}

/// dto/response/customer/CustomerResponse.java
class Customer {
  const Customer({
    required this.id,
    this.code,
    required this.name,
    this.phone,
    this.email,
    this.note,
    this.status,
  });

  final int id;
  final String? code;
  final String name;
  final String? phone;
  final String? email;
  final String? note;
  final String? status;

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        id: j.intOf('id') ?? 0,
        code: j.stringOf('code'),
        name: j.stringOf('name') ?? '',
        phone: j.stringOf('phone'),
        email: j.stringOf('email'),
        note: j.stringOf('note'),
        status: j.stringOf('status'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'phone': phone,
        'email': email,
        'note': note,
        'status': status,
      };
}

class CustomerRequest {
  const CustomerRequest({
    required this.code,
    required this.name,
    this.phone,
    this.email,
    this.note,
    this.status = 'ACT',
  });

  final String code;
  final String name;
  final String? phone;
  final String? email;
  final String? note;
  final String status;

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'phone': phone,
        'email': email,
        'note': note,
        'status': status,
      };
}

/// dto/response/quote/QuoteResponse.java
class Quote {
  const Quote({
    required this.id,
    this.date,
    this.reference,
    this.no,
    this.customerId,
    this.grandTotal,
    this.discount,
    this.status,
    this.statusPayment,
    this.paidAmount,
    this.noted,
    this.items = const [],
  });

  final int id;
  final String? date;
  final String? reference;
  final String? no;
  final int? customerId;
  final double? grandTotal;
  final double? discount;
  final String? status;
  final String? statusPayment;
  final double? paidAmount;
  final String? noted;
  final List<QuoteItem> items;

  factory Quote.fromJson(Map<String, dynamic> j) => Quote(
        id: j.intOf('id') ?? 0,
        date: j.stringOf('date'),
        reference: j.stringOf('reference'),
        no: j.stringOf('no'),
        customerId: j.intOf('customerId'),
        grandTotal: j.doubleOf('grandTotal'),
        discount: j.doubleOf('discount'),
        status: j.stringOf('status'),
        statusPayment: j.stringOf('statusPayment'),
        paidAmount: j.doubleOf('paidAmount'),
        noted: j.stringOf('noted'),
        items: j.listOf('items').map(QuoteItem.fromJson).toList(),
      );
}

class QuoteItem {
  const QuoteItem({this.productId, this.price, this.qty, this.discountItem, this.subtotal});
  final int? productId;
  final double? price;
  final double? qty;
  final double? discountItem;
  final double? subtotal;

  factory QuoteItem.fromJson(Map<String, dynamic> j) => QuoteItem(
        productId: j.intOf('productId'),
        price: j.doubleOf('price'),
        qty: j.doubleOf('qty'),
        discountItem: j.doubleOf('discount_item'),
        subtotal: j.doubleOf('subtotal'),
      );
}

class QuoteRequest {
  const QuoteRequest({
    required this.customerId,
    this.discount,
    this.noted,
    this.reference,
    this.no,
    this.status,
    this.paymentStatus,
    required this.items,
  });

  final int customerId;
  final double? discount;
  final String? noted;
  final String? reference;
  final String? no;
  final String? status;
  final String? paymentStatus;
  final List<QuoteItemRequest> items;

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        'discount': discount ?? 0,
        if (noted != null) 'noted': noted,
        if (reference != null) 'reference': reference,
        if (no != null) 'no': no,
        if (status != null) 'status': status,
        if (paymentStatus != null) 'paymentStatus': paymentStatus,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

class QuoteItemRequest {
  const QuoteItemRequest({
    required this.productId,
    required this.price,
    required this.qty,
    this.discountItem,
  });
  final int productId;
  final double price;
  final num qty;
  final double? discountItem;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'price': price,
        'qty': qty,
        'discount_item': discountItem ?? 0,
      };
}
