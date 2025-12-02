import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction_entity.dart';
import '../../data/repositories/transaction_repository.dart';
import 'repository_providers.dart';

/// All transactions provider
final allTransactionsProvider = FutureProvider<List<TransactionEntity>>((ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getAllTransactions();
});

/// Transactions by month provider
final transactionsByMonthProvider = FutureProvider.family<List<TransactionEntity>, ({int year, int month})>((ref, params) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getTransactionsByMonth(year: params.year, month: params.month);
});

/// Transactions by date range provider
final transactionsByDateRangeProvider = FutureProvider.family<List<TransactionEntity>, ({String startDate, String endDate})>((ref, params) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getTransactionsByDateRange(startDate: params.startDate, endDate: params.endDate);
});

/// Transactions by category provider
final transactionsByCategoryProvider = FutureProvider.family<List<TransactionEntity>, int>((ref, categoryId) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getTransactionsByCategory(categoryId);
});

/// Credits (income) provider
final creditsProvider = FutureProvider.family<List<TransactionEntity>, ({String? startDate, String? endDate})>((ref, params) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getCredits(startDate: params.startDate, endDate: params.endDate);
});

/// Debits (expenses) provider
final debitsProvider = FutureProvider.family<List<TransactionEntity>, ({String? startDate, String? endDate})>((ref, params) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getDebits(startDate: params.startDate, endDate: params.endDate);
});

/// Monthly summary provider
final monthlySummaryProvider = FutureProvider.family<Map<String, dynamic>, ({int year, int month})>((ref, params) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getMonthlySummary(year: params.year, month: params.month);
});

/// Today's summary provider
final todaySummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getTodaySummary();
});

/// Latest transaction provider (for current balance)
final latestTransactionProvider = FutureProvider<TransactionEntity?>((ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  // Use the latest transaction that has a parsed balanceAfter value
  // so the "Current Balance" card always shows the real last known balance.
  return await repository.getLatestTransactionWithBalance();
});

/// Transaction by ID provider
final transactionByIdProvider = FutureProvider.family<TransactionEntity?, int>((ref, id) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return await repository.getTransactionById(id);
});


