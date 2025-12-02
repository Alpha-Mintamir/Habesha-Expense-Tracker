import '../dao/transaction_dao.dart';
import '../models/transaction_entity.dart';

class TransactionRepository {
  final TransactionDao _dao = TransactionDao();

  /// Add a transaction from parsed SMS data
  Future<int> addFromSms(TransactionEntity transaction) async {
    return await _dao.insert(transaction);
  }

  /// Get all transactions
  Future<List<TransactionEntity>> getAllTransactions({
    int? limit,
    int? offset,
  }) async {
    return await _dao.getAll(limit: limit, offset: offset);
  }

  /// Get transaction by ID
  Future<TransactionEntity?> getTransactionById(int id) async {
    return await _dao.getById(id);
  }

  /// Get transactions for a specific month
  Future<List<TransactionEntity>> getTransactionsByMonth({
    required int year,
    required int month,
  }) async {
    return await _dao.getByMonth(year: year, month: month);
  }

  /// Get transactions within a date range
  Future<List<TransactionEntity>> getTransactionsByDateRange({
    required String startDate, // 'yyyy-MM-dd'
    required String endDate,   // 'yyyy-MM-dd'
  }) async {
    return await _dao.getByDateRange(startDate: startDate, endDate: endDate);
  }

  /// Get transactions by category
  Future<List<TransactionEntity>> getTransactionsByCategory(int categoryId) async {
    return await _dao.getByCategory(categoryId);
  }

  /// Get transactions by message type
  Future<List<TransactionEntity>> getTransactionsByType(String messageType) async {
    return await _dao.getByMessageType(messageType);
  }

  /// Get all credit transactions (income)
  Future<List<TransactionEntity>> getCredits({
    String? startDate,
    String? endDate,
  }) async {
    return await _dao.getCredits(startDate: startDate, endDate: endDate);
  }

  /// Get all debit transactions (expenses)
  Future<List<TransactionEntity>> getDebits({
    String? startDate,
    String? endDate,
  }) async {
    return await _dao.getDebits(startDate: startDate, endDate: endDate);
  }

  /// Update transaction category
  Future<int> updateTransactionCategory(int transactionId, int? categoryId) async {
    return await _dao.updateCategory(transactionId, categoryId);
  }

  /// Update full transaction
  Future<int> updateTransaction(TransactionEntity transaction) async {
    return await _dao.update(transaction);
  }

  /// Delete transaction
  Future<int> deleteTransaction(int id) async {
    return await _dao.delete(id);
  }

  /// Get total income for a period
  Future<double> getTotalIncome({
    String? startDate,
    String? endDate,
  }) async {
    return await _dao.getTotalCredits(startDate: startDate, endDate: endDate);
  }

  /// Get total expenses for a period
  Future<double> getTotalExpenses({
    String? startDate,
    String? endDate,
  }) async {
    return await _dao.getTotalDebits(startDate: startDate, endDate: endDate);
  }

  /// Get total service charges for a period
  Future<double> getTotalServiceCharges({
    String? startDate,
    String? endDate,
  }) async {
    return await _dao.getTotalServiceCharges(startDate: startDate, endDate: endDate);
  }

  /// Get latest transaction (for current balance)
  Future<TransactionEntity?> getLatestTransaction() async {
    return await _dao.getLatestTransaction();
  }

  /// Get latest transaction that has a parsed balanceAfter value.
  /// Used for the "Current Balance" card so we always show the true last known balance.
  Future<TransactionEntity?> getLatestTransactionWithBalance() async {
    return await _dao.getLatestTransactionWithBalance();
  }

  /// Get monthly summary
  Future<Map<String, dynamic>> getMonthlySummary({
    required int year,
    required int month,
  }) async {
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = '$year-${month.toString().padLeft(2, '0')}-31';

    final income = await getTotalIncome(startDate: startDate, endDate: endDate);
    final expenses = await getTotalExpenses(startDate: startDate, endDate: endDate);
    final fees = await getTotalServiceCharges(startDate: startDate, endDate: endDate);

    return {
      'income': income,
      'expenses': expenses,
      'fees': fees,
      'net': income - expenses,
    };
  }

  /// Get today's summary
  Future<Map<String, dynamic>> getTodaySummary() async {
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final income = await getTotalIncome(startDate: dateStr, endDate: dateStr);
    final expenses = await getTotalExpenses(startDate: dateStr, endDate: dateStr);
    final fees = await getTotalServiceCharges(startDate: dateStr, endDate: dateStr);

    return {
      'income': income,
      'expenses': expenses,
      'fees': fees,
      'net': income - expenses,
    };
  }
}


