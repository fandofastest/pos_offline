import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<List<Category>> getAll() async {
    final Database database = await _db.database;
    final rows = await database.query('categories', orderBy: 'name ASC');
    return rows
        .map((e) => Category(id: e['id'] as int, name: e['name'] as String))
        .toList(growable: false);
  }

  @override
  Future<int> upsert(Category category) async {
    final Database database = await _db.database;
    if (category.id == null) {
      return database.insert('categories', {'name': category.name.trim()});
    }
    await database.update(
      'categories',
      {'name': category.name.trim()},
      where: 'id = ?',
      whereArgs: [category.id],
    );
    return category.id!;
  }

  @override
  Future<void> delete(int id) async {
    final Database database = await _db.database;
    await database.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
