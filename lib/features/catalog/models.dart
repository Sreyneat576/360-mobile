import '../../core/utils/formatters.dart';

/// Mirrors dto/response/catalog/ProductResponse.java
class Product {
  const Product({
    required this.id,
    this.code,
    this.name,
    this.costPrice,
    this.salePrice,
    this.noted,
    this.imageUrl,
    this.status,
    this.reorderLevel,
    this.qty,
    this.modelId,
    this.modelName,
    this.brandName,
    this.categoryName,
    this.variantValues = const [],
    this.createdAt,
  });

  final int id;
  final String? code;
  final String? name;
  final double? costPrice;
  final double? salePrice;
  final String? noted;
  final String? imageUrl;
  final String? status;
  final int? reorderLevel;

  /// Sum of stock quantity across all stores.
  final double? qty;
  final int? modelId;
  final String? modelName;
  final String? brandName;
  final String? categoryName;
  final List<VariantValue> variantValues;
  final String? createdAt;

  String get displayName => (name?.trim().isNotEmpty ?? false)
      ? name!.trim()
      : (modelName ?? 'Product #$id');

  double get price => salePrice ?? 0;
  double get stock => qty ?? 0;

  bool get isOutOfStock => stock <= 0;
  bool get isLowStock =>
      !isOutOfStock && reorderLevel != null && reorderLevel! > 0 && stock <= reorderLevel!;

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j.intOf('id') ?? 0,
        code: j.stringOf('code'),
        name: j.stringOf('name'),
        costPrice: j.doubleOf('costPrice'),
        salePrice: j.doubleOf('salePrice'),
        noted: j.stringOf('noted'),
        imageUrl: j.stringOf('imageUrl'),
        status: j.stringOf('status'),
        reorderLevel: j.intOf('reorderLevel'),
        qty: j.doubleOf('qty'),
        modelId: j.intOf('modelId'),
        modelName: j.stringOf('modelName'),
        brandName: j.stringOf('brandName'),
        categoryName: j.stringOf('categoryName'),
        variantValues: j.listOf('variantValues').map(VariantValue.fromJson).toList(),
        createdAt: j.stringOf('createdAt'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'costPrice': costPrice,
        'salePrice': salePrice,
        'noted': noted,
        'imageUrl': imageUrl,
        'status': status,
        'reorderLevel': reorderLevel,
        'qty': qty,
        'modelId': modelId,
        'modelName': modelName,
        'brandName': brandName,
        'categoryName': categoryName,
      };
}

/// dto/request/catalog/ProductRequest.java
class ProductRequest {
  const ProductRequest({
    this.code,
    this.name,
    this.costPrice,
    this.salePrice,
    this.noted,
    this.imageUrl,
    this.status,
    this.reorderLevel,
    required this.modelId,
    this.variantValueIds,
  });

  final String? code;
  final String? name;
  final double? costPrice;
  final double? salePrice;
  final String? noted;
  final String? imageUrl;
  final String? status;
  final int? reorderLevel;
  final int modelId;
  final List<int>? variantValueIds;

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'costPrice': costPrice,
        'salePrice': salePrice,
        'noted': noted,
        'imageUrl': imageUrl,
        'status': status,
        'reorderLevel': reorderLevel,
        'modelId': modelId,
        if (variantValueIds != null) 'variantValueIds': variantValueIds,
      };
}

/// dto/response/catalog/ProductDetailResponse.java
class ProductDetail {
  const ProductDetail({
    required this.id,
    this.name,
    this.brandId,
    this.brandName,
    this.categoryId,
    this.categoryName,
    this.modelId,
    this.modelName,
    this.reorderLevel,
    this.quantity,
    this.availableSerials,
    this.serials = const [],
  });

  final int id;
  final String? name;
  final int? brandId;
  final String? brandName;
  final int? categoryId;
  final String? categoryName;
  final int? modelId;
  final String? modelName;
  final int? reorderLevel;
  final double? quantity;
  final int? availableSerials;
  final List<SerialInfo> serials;

  factory ProductDetail.fromJson(Map<String, dynamic> j) => ProductDetail(
        id: j.intOf('id') ?? 0,
        name: j.stringOf('name'),
        brandId: j.intOf('brandId'),
        brandName: j.stringOf('brandName'),
        categoryId: j.intOf('categoryId'),
        categoryName: j.stringOf('categoryName'),
        modelId: j.intOf('modelId'),
        modelName: j.stringOf('modelName'),
        reorderLevel: j.intOf('reorderLevel'),
        quantity: j.doubleOf('quantity'),
        availableSerials: j.intOf('availableSerials'),
        serials: j.listOf('serials').map(SerialInfo.fromJson).toList(),
      );
}

class SerialInfo {
  const SerialInfo({
    required this.id,
    this.serialNumber,
    this.barcode,
    this.costPrice,
    this.sellingPrice,
    this.status,
  });

  final int id;

  /// The serial's own barcode (ProductSerials.barcode).
  final String? serialNumber;

  /// The product code (see ProductServiceImpl.getProductDetail).
  final String? barcode;
  final double? costPrice;
  final double? sellingPrice;
  final String? status;

  factory SerialInfo.fromJson(Map<String, dynamic> j) => SerialInfo(
        id: j.intOf('id') ?? 0,
        serialNumber: j.stringOf('serialNumber'),
        barcode: j.stringOf('barcode'),
        costPrice: j.doubleOf('costPrice'),
        sellingPrice: j.doubleOf('sellingPrice'),
        status: j.stringOf('status'),
      );
}

/// dto/response/catalog/ProductSerialResponse.java
///
/// A row is either a serialised unit (barcode set, quantity 1) or a bulk lot
/// (no barcode, quantity = lot size). See StockServiceImpl.
class ProductSerial {
  const ProductSerial({
    required this.id,
    this.productId,
    this.productName,
    this.storeId,
    this.storeName,
    this.barcode,
    this.price,
    this.cost,
    this.quantity,
    this.status,
    this.createdAt,
    this.purchaseId,
  });

  final int id;
  final int? productId;
  final String? productName;
  final int? storeId;
  final String? storeName;
  final String? barcode;
  final double? price;
  final double? cost;
  final double? quantity;
  final String? status;
  final String? createdAt;
  final int? purchaseId;

  bool get isAvailable => (status ?? '').toUpperCase() == 'AVAILABLE';
  bool get isSerialised => (barcode ?? '').trim().isNotEmpty;

  factory ProductSerial.fromJson(Map<String, dynamic> j) => ProductSerial(
        id: j.intOf('id') ?? 0,
        productId: j.intOf('productId'),
        productName: j.stringOf('productName'),
        storeId: j.intOf('storeId'),
        storeName: j.stringOf('storeName'),
        barcode: j.stringOf('barcode'),
        price: j.doubleOf('price'),
        cost: j.doubleOf('cost'),
        quantity: j.doubleOf('quantity'),
        status: j.stringOf('status'),
        createdAt: j.stringOf('createdAt'),
        purchaseId: j.intOf('purchaseId'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'productName': productName,
        'storeId': storeId,
        'storeName': storeName,
        'barcode': barcode,
        'price': price,
        'cost': cost,
        'quantity': quantity,
        'status': status,
      };
}

class Category {
  const Category({required this.id, required this.name, this.code, this.imageUrl, this.status});
  final int id;
  final String name;
  final String? code;
  final String? imageUrl;
  final String? status;

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j.intOf('id') ?? 0,
        name: j.stringOf('name') ?? '',
        code: j.stringOf('code'),
        imageUrl: j.stringOf('imageUrl'),
        status: j.stringOf('status'),
      );
}

class Brand {
  const Brand({required this.id, required this.name, this.imageUrl, this.status});
  final int id;
  final String name;
  final String? imageUrl;
  final String? status;

  factory Brand.fromJson(Map<String, dynamic> j) => Brand(
        id: j.intOf('id') ?? 0,
        name: j.stringOf('name') ?? '',
        imageUrl: j.stringOf('imageUrl'),
        status: j.stringOf('status'),
      );
}

class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    this.categoryId,
    this.categoryName,
    this.brandId,
    this.brandName,
    this.status,
  });
  final int id;
  final String name;
  final int? categoryId;
  final String? categoryName;
  final int? brandId;
  final String? brandName;
  final String? status;

  factory ProductModel.fromJson(Map<String, dynamic> j) => ProductModel(
        id: j.intOf('id') ?? 0,
        name: j.stringOf('name') ?? '',
        categoryId: j.intOf('categoryId'),
        categoryName: j.stringOf('categoryName'),
        brandId: j.intOf('brandId'),
        brandName: j.stringOf('brandName'),
        status: j.stringOf('status'),
      );
}

class VariantValue {
  const VariantValue({
    required this.id,
    required this.name,
    this.code,
    this.variantTypeId,
    this.variantTypeName,
  });
  final int id;
  final String name;
  final String? code;
  final int? variantTypeId;
  final String? variantTypeName;

  factory VariantValue.fromJson(Map<String, dynamic> j) => VariantValue(
        id: j.intOf('id') ?? 0,
        name: j.stringOf('name') ?? '',
        code: j.stringOf('code'),
        variantTypeId: j.intOf('variantTypeId'),
        variantTypeName: j.stringOf('variantTypeName'),
      );
}
