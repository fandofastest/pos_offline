import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/product_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoryRepositoryImpl(db);
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ProductRepositoryImpl(db);
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getAll();
});

final productQueryProvider = StateProvider<String>((ref) => '');

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final query = ref.watch(productQueryProvider);
  return repo.getAll(query: query);
});
