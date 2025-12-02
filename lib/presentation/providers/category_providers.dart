import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/category.dart';
import '../../data/repositories/category_repository.dart';
import 'repository_providers.dart';

/// All categories provider
final allCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return await repository.getAllCategories();
});

/// Default categories provider
final defaultCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return await repository.getDefaultCategories();
});

/// Category by ID provider
final categoryByIdProvider = FutureProvider.family<Category?, int>((ref, id) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return await repository.getCategoryById(id);
});





