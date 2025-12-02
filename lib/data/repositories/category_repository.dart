import '../dao/category_dao.dart';
import '../models/category.dart';

class CategoryRepository {
  final CategoryDao _dao = CategoryDao();

  Future<List<Category>> getAllCategories() async {
    return await _dao.getAll();
  }

  Future<List<Category>> getDefaultCategories() async {
    return await _dao.getDefaultCategories();
  }

  Future<Category?> getCategoryById(int id) async {
    return await _dao.getById(id);
  }

  Future<Category?> getCategoryByName(String name) async {
    return await _dao.getByName(name);
  }

  Future<int> addCategory(String name) async {
    final category = Category(
      name: name,
      isDefault: false,
      createdAt: DateTime.now().toIso8601String(),
    );
    return await _dao.insert(category);
  }

  Future<int> updateCategory(Category category) async {
    return await _dao.update(category);
  }

  Future<int> deleteCategory(int id) async {
    return await _dao.delete(id);
  }

  Future<bool> categoryExists(String name) async {
    final category = await _dao.getByName(name);
    return category != null;
  }
}





