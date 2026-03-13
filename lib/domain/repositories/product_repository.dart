import '../entities/product.dart';

abstract interface class ProductRepository {
  Future<List<Product>> getAll({String? query});
  Future<Product?> getById(int id);
  Future<Product?> getByBarcode(String barcode);
  Future<int> upsert(Product product);
  Future<void> delete(int id);
  Future<void> reduceStock({required int productId, required double quantity});
}
