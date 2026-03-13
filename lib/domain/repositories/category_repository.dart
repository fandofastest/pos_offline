import '../entities/category.dart';

abstract interface class CategoryRepository {
  Future<List<Category>> getAll();
  Future<int> upsert(Category category);
  Future<void> delete(int id);
}
