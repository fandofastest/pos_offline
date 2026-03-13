import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._db);

  final AppDatabase _db;

  Product _map(Map<String, Object?> e) {
    return Product(
      id: e['id'] as int,
      name: e['name'] as String,
      barcode: e['barcode'] as String?,
      categoryId: e['category_id'] as int?,
      price: (e['price'] as num).toDouble(),
      stock: (e['stock'] as num).toDouble(),
      unit: e['unit'] as String,
    );
  }

  @override
  Future<Product?> getById(int id) async {
    final Database database = await _db.database;
    final rows = await database.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _map(rows.first);
  }

  @override
  Future<List<Product>> getAll({String? query}) async {
    final Database database = await _db.database;

    final q = query?.trim();
    if (q == null || q.isEmpty) {
      final rows = await database.query('products', orderBy: 'name ASC');
      return rows.map(_map).toList(growable: false);
    }

    final rows = await database.query(
      'products',
      where: 'name LIKE ? OR barcode LIKE ?',
      whereArgs: ['%$q%', '%$q%'],
      orderBy: 'name ASC',
    );
    return rows.map(_map).toList(growable: false);
  }

  @override
  Future<Product?> getByBarcode(String barcode) async {
    final Database database = await _db.database;
    final rows = await database.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode.trim()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _map(rows.first);
  }

  @override
  Future<int> upsert(Product product) async {
    final Database database = await _db.database;
    final values = <String, Object?>{
      'name': product.name.trim(),
      'barcode': product.barcode?.trim(),
      'category_id': product.categoryId,
      'price': product.price,
      'stock': product.stock,
      'unit': product.unit.trim(),
    };

    if (product.id == null) {
      return database.insert('products', values);
    }

    await database.update(
      'products',
      values,
      where: 'id = ?',
      whereArgs: [product.id],
    );
    return product.id!;
  }

  @override
  Future<void> delete(int id) async {
    final Database database = await _db.database;
    await database.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> reduceStock({required int productId, required double quantity}) async {
    final Database database = await _db.database;
    await database.rawUpdate(
      'UPDATE products SET stock = stock - ? WHERE id = ?',
      [quantity, productId],
    );
  }
}
