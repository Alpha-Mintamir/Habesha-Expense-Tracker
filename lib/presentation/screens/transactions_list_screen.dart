import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_providers.dart';
import '../../core/constants/message_type.dart';
import '../../data/models/transaction_entity.dart';
import 'package:intl/intl.dart';
import 'transaction_details_screen.dart';

enum TransactionSort {
  newest,
  oldest,
  amountHigh,
  amountLow,
}

class TransactionsListScreen extends ConsumerStatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  ConsumerState<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends ConsumerState<TransactionsListScreen> {
  String _searchQuery = '';
  String? _selectedType;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _useMonthFilter = true;
  TransactionSort _sort = TransactionSort.newest;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TransactionEntity> _filterTransactions(List<TransactionEntity> transactions) {
    final filtered = transactions.where((tx) {
      // Month / Year filter
      if (_useMonthFilter) {
        final txDate = DateTime.parse(tx.date);
        if (txDate.year != _selectedYear || txDate.month != _selectedMonth) {
          return false;
        }
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesSearch = 
            (tx.sender?.toLowerCase().contains(query) ?? false) ||
            (tx.receiver?.toLowerCase().contains(query) ?? false) ||
            (tx.refNo?.toLowerCase().contains(query) ?? false);
        if (!matchesSearch) return false;
      }

      // Type filter
      if (_selectedType != null && tx.messageType != _selectedType) {
        return false;
      }

      return true;
    }).toList();

    // Sorting
    filtered.sort((a, b) {
      switch (_sort) {
        case TransactionSort.newest:
          return DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt));
        case TransactionSort.oldest:
          return DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt));
        case TransactionSort.amountHigh:
          return b.amount.compareTo(a.amount);
        case TransactionSort.amountLow:
          return a.amount.compareTo(b.amount);
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final allTransactions = ref.watch(allTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        elevation: 0,
        actions: [
          PopupMenuButton<TransactionSort>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sort = value;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: TransactionSort.newest,
                child: Text('Newest first'),
              ),
              PopupMenuItem(
                value: TransactionSort.oldest,
                child: Text('Oldest first'),
              ),
              PopupMenuItem(
                value: TransactionSort.amountHigh,
                child: Text('Amount high → low'),
              ),
              PopupMenuItem(
                value: TransactionSort.amountLow,
                child: Text('Amount low → high'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or ref no...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Month / Year selector
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedMonth,
                        decoration: const InputDecoration(
                          labelText: 'Month',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(12, (index) {
                          final month = index + 1;
                          return DropdownMenuItem(
                            value: month,
                            child: Text(DateFormat('MMMM').format(DateTime(2000, month, 1))),
                          );
                        }),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedMonth = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedYear,
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(5, (index) {
                          final year = DateTime.now().year - index;
                          return DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedYear = value;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _useMonthFilter ? Icons.filter_alt : Icons.filter_alt_off,
                        color: _useMonthFilter ? Theme.of(context).colorScheme.primary : null,
                      ),
                      tooltip: _useMonthFilter ? 'Showing selected month' : 'Show all time',
                      onPressed: () {
                        setState(() {
                          _useMonthFilter = !_useMonthFilter;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Type Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Type Filter
                      FilterChip(
                        label: const Text('All Types'),
                        selected: _selectedType == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Credits'),
                        selected: _selectedType == MessageType.creditDetailed || 
                                  _selectedType == MessageType.creditSimple,
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = selected ? MessageType.creditDetailed : null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Debits'),
                        selected: _selectedType == MessageType.debitTransfer || 
                                  _selectedType == MessageType.debitSimple,
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = selected ? MessageType.debitTransfer : null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Transactions List
          Expanded(
            child: allTransactions.when(
              data: (transactions) {
                final filtered = _filterTransactions(transactions);
                
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _selectedType != null
                              ? 'No transactions match your filters'
                              : 'No transactions yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(allTransactionsProvider);
                  },
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final transaction = filtered[index];
                      final isCredit = transaction.messageType == MessageType.creditDetailed ||
                                       transaction.messageType == MessageType.creditSimple;
                      
                      return _TransactionListItem(
                        transaction: transaction,
                        isCredit: isCredit,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionDetailsScreen(
                                transactionId: transaction.id!,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $err'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(allTransactionsProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionListItem extends StatelessWidget {
  final TransactionEntity transaction;
  final bool isCredit;
  final VoidCallback onTap;

  const _TransactionListItem({
    required this.transaction,
    required this.isCredit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final amount = transaction.amount;
    final color = isCredit ? Colors.green : Colors.red;
    final prefix = isCredit ? '+' : '-';
    
    String displayName = 'Unknown';
    if (transaction.sender != null) {
      displayName = transaction.sender!;
    } else if (transaction.receiver != null) {
      displayName = transaction.receiver!;
    } else if (transaction.messageType == MessageType.creditSimple) {
      displayName = 'Unknown Credit';
    } else if (transaction.messageType == MessageType.debitSimple) {
      displayName = 'Unknown Debit';
    }

    final dateTime = DateTime.parse(transaction.createdAt);
    final timeStr = DateFormat('HH:mm').format(dateTime);
    final dateStr = DateFormat('MMM dd').format(dateTime);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(
            isCredit ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('$dateStr • $timeStr'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$prefix ETB ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
            if (transaction.serviceCharge != null)
              Text(
                'Fee: ETB ${transaction.serviceCharge!.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

