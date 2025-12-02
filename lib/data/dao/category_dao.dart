import 'package:sqflite/sqflite.dart';
import '../db/app_database.dart';
import '../models/category.dart';
import '../../core/constants/db_constants.dart';

class CategoryDao {
  final AppDatabase _db = AppDatabase();

  Future<int> insert(Category category) async {
    final db = await _db.database;
    return await db.insert(
      DbConstants.tableCategories,
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Category>> getAll() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableCategories,
      orderBy: '${DbConstants.colIsDefault} DESC, ${DbConstants.colName} ASC',
    );
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<List<Category>> getDefaultCategories() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableCategories,
      where: '${DbConstants.colIsDefault} = ?',
      whereArgs: [1],
      orderBy: DbConstants.colName,
    );
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<Category?> getById(int id) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableCategories,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  Future<Category?> getByName(String name) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableCategories,
      where: '${DbConstants.colName} = ?',
      whereArgs: [name],
    );
    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  Future<int> update(Category category) async {
    final db = await _db.database;
    return await db.update(
      DbConstants.tableCategories,
      category.toMap(),
      where: '${DbConstants.colId} = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    // Check if category is default - don't allow deletion
    final category = await getById(id);
    if (category != null && category.isDefault) {
      throw Exception('Cannot delete default category');
    }
    return await db.delete(
      DbConstants.tableCategories,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteByName(String name) async {
    final category = await getByName(name);
    if (category == null) return 0;
    return await delete(category.id!);
  }
}

