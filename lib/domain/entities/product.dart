class Product {
  const Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.categoryId,
    required this.price,
    required this.stock,
    required this.unit,
  });

  final int? id;
  final String name;
  final String? barcode;
  final int? categoryId;
  final double price;
  final double stock;
  final String unit;

  Product copyWith({
    int? id,
    String? name,
    String? barcode,
    int? categoryId,
    double? price,
    double? stock,
    String? unit,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
    );
  }
}
