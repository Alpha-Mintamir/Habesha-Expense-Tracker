import 'package:sqflite/sqflite.dart';
import '../db/app_database.dart';
import '../models/transaction_entity.dart';
import '../../core/constants/db_constants.dart';

class TransactionDao {
  final AppDatabase _db = AppDatabase();

  Future<int> insert(TransactionEntity transaction) async {
    final db = await _db.database;
    return await db.insert(
      DbConstants.tableTransactions,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TransactionEntity>> getAll({
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableTransactions,
      orderBy: orderBy ?? '${DbConstants.colDate} DESC, ${DbConstants.colTime} DESC',
      limit: limit,
      offset: offset,
    );
    return List.generate(maps.length, (i) => TransactionEntity.fromMap(maps[i]));
  }

  Future<TransactionEntity?> getById(int id) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableTransactions,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return TransactionEntity.fromMap(maps.first);
  }

  Future<List<TransactionEntity>> getByDateRange({
    required String startDate,
    required String endDate,
  }) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableTransactions,
      where: '${DbConstants.colDate} >= ? AND ${DbConstants.colDate} <= ?',
      whereArgs: [startDate, endDate],
      orderBy: '${DbConstants.colDate} DESC, ${DbConstants.colTime} DESC',
    );
    return List.generate(maps.length, (i) => TransactionEntity.fromMap(maps[i]));
  }

  Future<List<TransactionEntity>> getByMonth({
    required int year,
    required int month,
  }) async {
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = '$year-${month.toString().padLeft(2, '0')}-31';
    return await getByDateRange(startDate: startDate, endDate: endDate);
  }

  Future<List<TransactionEntity>> getByCategory(int categoryId) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableTransactions,
      where: '${DbConstants.colCategoryId} = ?',
      whereArgs: [categoryId],
      orderBy: '${DbConstants.colDate} DESC, ${DbConstants.colTime} DESC',
    );
    return List.generate(maps.length, (i) => TransactionEntity.fromMap(maps[i]));
  }

  Future<List<TransactionEntity>> getByMessageType(String messageType) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableTransactions,
      where: '${DbConstants.colMessageType} = ?',
      whereArgs: [messageType],
      orderBy: '${DbConstants.colDate} DESC, ${DbConstants.colTime} DESC',
    );
    return List.generate(maps.length, (i) => TransactionEntity.fromMap(maps[i]));
  }

  Future<List<TransactionEntity>> getCredits({
    String? startDate,
    String? endDate,
  }) async {
    final db = await _db.database;
    String? where;
    List<Object?>? whereArgs;

    if (startDate != null && endDate != null) {
      where = '${DbConstants.colMessageType} IN (?, ?) AND ${DbConstants.colDate} >= ? AND ${DbConstants.colDate} <= ?';
      whereArgs = [
        'credit_detailed',
        'credit_simple',
        startDate,
        endDate,
      ];
    } else {
      where = '${DbConstants.colMessageType} IN (?, ?)';
      whereArgs = ['credit_detailed', 'credit_simple'];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableTransactions,
      where: where,
      whereArgs: whereArgs,
      orderBy: '${DbConstants.colDate} DESC, ${DbConstants.colTime} DESC',
    );
    return List.generate(maps.length, (i) => TransactionEntity.fromMap(maps[i]));
  }

  Future<List<TransactionEntity>> getDebits({
    String? startDate,
    String? endDate,
  }) async {
    final db = await _db.database;
    String? where;
    List<Object?>? whereArgs;

    if (startDate != null && endDate != null) {
      where = '${DbConstants.colMessageType} IN (?, ?) AND ${DbConstants.colDate} >= ? AND ${DbConstants.colDate} <= ?';
      whereArgs = [
        'debit_transfer',
        'debit_simple',
        startDate,
        endDate,
      ];
    } else {
      where = '${DbConstants.colMessageType} IN (?, ?)';
      whereArgs = ['debit_transfer', 'debit_simple'];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableTransactions,
      where: where,
      whereArgs: whereArgs,
      orderBy: '${DbConstants.colDate} DESC, ${DbConstants.colTime} DESC',
    );
    return List.generate(maps.length, (i) => TransactionEntity.fromMap(maps[i]));
  }

  Future<int> update(TransactionEntity transaction) async {
    final db = await _db.database;
    return await db.update(
      DbConstants.tableTransactions,
      transaction.toMap(),
      where: '${DbConstants.colId} = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> updateCategory(int transactionId, int? categoryId) async {
    final db = await _db.database;
    return await db.update(
      DbConstants.tableTransactions,
      {DbConstants.colCategoryId: categoryId},
      where: '${DbConstants.colId} = ?',
      whereArgs: [transactionId],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete(
      DbConstants.tableTransactions,
      where: '${DbConstants.colId} = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalCredits({
    String? startDate,
    String? endDate,
  }) async {
    final credits = await getCredits(startDate: startDate, endDate: endDate);
    var total = 0.0;
    for (final t in credits) {
      total += t.amount;
    }
    return total;
  }

  Future<double> getTotalDebits({
    String? startDate,
    String? endDate,
  }) async {
    final debits = await getDebits(startDate: startDate, endDate: endDate);
    var total = 0.0;
    for (final t in debits) {
      total += t.amount;
    }
    return total;
  }

  Future<double> getTotalServiceCharges({
    String? startDate,
    String? endDate,
  }) async {
    final db = await _db.database;
    String? where;
    List<Object?>? whereArgs;

    if (startDate != null && endDate != null) {
      where = '${DbConstants.colServiceCharge} IS NOT NULL AND ${DbConstants.colDate} >= ? AND ${DbConstants.colDate} <= ?';
      whereArgs = [startDate, endDate];
    } else {
      where = '${DbConstants.colServiceCharge} IS NOT NULL';
    }

    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableTransactions,
      columns: [DbConstants.colServiceCharge],
      where: where,
      whereArgs: whereArgs,
    );

    var total = 0.0;
    for (final map in maps) {
      final charge = map[DbConstants.colServiceCharge] as num?;
      total += (charge?.toDouble() ?? 0.0);
    }
    return total;
  }

  /// Get the very latest transaction (by date + time)
  Future<TransactionEntity?> getLatestTransaction() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableTransactions,
      orderBy: '${DbConstants.colDate} DESC, ${DbConstants.colTime} DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TransactionEntity.fromMap(maps.first);
  }

  /// Get the latest transaction that has a non-null balanceAfter.
  /// This ensures the "Current Balance" card always shows a real parsed balance,
  /// even if the most recent SMS didn't include a balance.
  Future<TransactionEntity?> getLatestTransactionWithBalance() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableTransactions,
      where: '${DbConstants.colBalanceAfter} IS NOT NULL',
      orderBy: '${DbConstants.colDate} DESC, ${DbConstants.colTime} DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TransactionEntity.fromMap(maps.first);
  }
}

