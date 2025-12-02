import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_providers.dart';
import '../providers/sms_providers.dart';
import 'package:intl/intl.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthlySummary = ref.watch(
      monthlySummaryProvider((year: now.year, month: now.month)),
    );
    final todaySummary = ref.watch(todaySummaryProvider);
    final latestTransaction = ref.watch(latestTransactionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todaySummaryProvider);
          ref.invalidate(monthlySummaryProvider((year: now.year, month: now.month)));
          ref.invalidate(latestTransactionProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Current Balance Card
              latestTransaction.when(
                data: (transaction) => Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Balance',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ETB ${transaction?.balanceAfter?.toStringAsFixed(2) ?? '0.00'}',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        if (transaction != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Last transaction: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(transaction.createdAt))}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (err, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text('Error: $err'),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Monthly Summary Cards
              monthlySummary.when(
                data: (summary) => Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Monthly Income',
                        amount: summary['income'] as double? ?? 0.0,
                        color: Colors.green,
                        icon: Icons.arrow_downward,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Monthly Expense',
                        amount: summary['expenses'] as double? ?? 0.0,
                        color: Colors.red,
                        icon: Icons.arrow_upward,
                      ),
                    ),
                  ],
                ),
                loading: () => const Row(
                  children: [
                    Expanded(child: Card(child: Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())))),
                    SizedBox(width: 12),
                    Expanded(child: Card(child: Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())))),
                  ],
                ),
                error: (err, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error: $err'),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Fees Card
              monthlySummary.when(
                data: (summary) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_balance_wallet, color: Colors.orange),
                            const SizedBox(width: 12),
                            Text(
                              'Fees This Month',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        Text(
                          'ETB ${(summary['fees'] as double? ?? 0.0).toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // Today's Summary
              todaySummary.when(
                data: (summary) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Summary",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _TodayItem(
                              label: 'Income',
                              value: summary['income'] as double? ?? 0.0,
                              color: Colors.green,
                            ),
                            _TodayItem(
                              label: 'Expense',
                              value: summary['expenses'] as double? ?? 0.0,
                              color: Colors.red,
                            ),
                            _TodayItem(
                              label: 'Net',
                              value: summary['net'] as double? ?? 0.0,
                              color: (summary['net'] as double? ?? 0.0) >= 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (err, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error: $err'),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sync Button
              Consumer(
                builder: (context, ref, child) {
                  return _SyncButton(ref: ref);
                },
              ),
              const SizedBox(height: 16),

              // Add Manual Expense Button
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to manual entry screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Manual entry coming soon')),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Manual Expense'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'ETB ${amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _TodayItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          'ETB ${value.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _SyncButton extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _SyncButton({required this.ref});

  @override
  ConsumerState<_SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends ConsumerState<_SyncButton> {
  bool _isSyncing = false;

  Future<void> _handleSync() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final service = widget.ref.read(smsIngestionServiceProvider);
      final result = await service.syncNewSms();

      // Refresh all providers
      widget.ref.invalidate(allTransactionsProvider);
      widget.ref.invalidate(todaySummaryProvider);
      widget.ref.invalidate(latestTransactionProvider);
      
      final now = DateTime.now();
      widget.ref.invalidate(monthlySummaryProvider((year: now.year, month: now.month)));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['success'] == true
                  ? 'Synced ${result['synced']} new transaction(s)'
                  : 'Sync failed: ${result['error']}',
            ),
            backgroundColor: result['success'] == true ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isSyncing ? null : _handleSync,
      icon: _isSyncing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.sync),
      label: Text(_isSyncing ? 'Syncing...' : 'Sync New Transactions'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

