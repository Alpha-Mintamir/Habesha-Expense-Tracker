import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_providers.dart';
import '../../core/constants/message_type.dart';
import '../../data/models/transaction_entity.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    // Build YYYY-MM-DD strings for the selected month/year
    final startDateStr = DateFormat('yyyy-MM-dd').format(
      DateTime(_selectedYear, _selectedMonth, 1),
    );
    final endDateStr = DateFormat('yyyy-MM-dd').format(
      DateTime(_selectedYear, _selectedMonth + 1, 0),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allTransactionsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                ],
              ),
              const SizedBox(height: 24),

              // Summary Cards
              _buildSummaryCards(startDateStr, endDateStr),
              const SizedBox(height: 24),

              // Income vs Expense Chart
              _buildIncomeVsExpenseChart(startDateStr, endDateStr),
              const SizedBox(height: 24),

              // Balance Over Time Chart
              _buildBalanceOverTimeChart(startDateStr, endDateStr),
              const SizedBox(height: 24),

              // Fees Over Time Chart
              _buildFeesOverTimeChart(startDateStr, endDateStr),
              const SizedBox(height: 24),

              // Top Receivers
              _buildTopReceivers(startDateStr, endDateStr),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(String startDate, String endDate) {
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return transactionsAsync.when(
      data: (allTransactions) {
        final filtered = _filterTransactionsByDate(allTransactions, startDate, endDate);
        final income = _calculateTotal(filtered, isCredit: true);
        final expenses = _calculateTotal(filtered, isCredit: false);
        final net = income - expenses;

        return Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Income',
                amount: income,
                color: Colors.green,
                icon: Icons.trending_up,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Expenses',
                amount: expenses,
                color: Colors.red,
                icon: Icons.trending_down,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Net',
                amount: net,
                color: net >= 0 ? Colors.green : Colors.red,
                icon: net >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Text('Error: $err'),
    );
  }

  Widget _buildIncomeVsExpenseChart(String startDate, String endDate) {
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return transactionsAsync.when(
      data: (allTransactions) {
        final filtered = _filterTransactionsByDate(allTransactions, startDate, endDate);
        final monthlyData = _groupByMonth(filtered);

        if (monthlyData.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Income vs Expense',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxValue(monthlyData) * 1.2,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.grey[800]!,
                          tooltipRoundedRadius: 8,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= monthlyData.length) {
                                return const Text('');
                              }
                              final monthData = monthlyData[value.toInt()];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('MMM').format(monthData['date'] as DateTime),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${(value / 1000).toStringAsFixed(0)}K',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: monthlyData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: data['income'] as double,
                              color: Colors.green,
                              width: 16,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                            BarChartRodData(
                              toY: data['expense'] as double,
                              color: Colors.red,
                              width: 16,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendItem(color: Colors.green, label: 'Income'),
                    const SizedBox(width: 24),
                    _LegendItem(color: Colors.red, label: 'Expense'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
    );
  }

  Widget _buildBalanceOverTimeChart(String startDate, String endDate) {
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return transactionsAsync.when(
      data: (allTransactions) {
        final filtered = _filterTransactionsByDate(allTransactions, startDate, endDate);
        final balanceData = _calculateBalanceOverTime(filtered);

        if (balanceData.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Balance Over Time',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 250,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= balanceData.length) {
                                return const Text('');
                              }
                              final point = balanceData[value.toInt()];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('MMM dd').format(point['date'] as DateTime),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                            reservedSize: 40,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${(value / 1000).toStringAsFixed(0)}K',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: balanceData.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), entry.value['balance'] as double);
                          }).toList(),
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withOpacity(0.1),
                          ),
                        ),
                      ],
                      minY: 0,
                      maxY: _getMaxBalance(balanceData) * 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildFeesOverTimeChart(String startDate, String endDate) {
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return transactionsAsync.when(
      data: (allTransactions) {
        final filtered = _filterTransactionsByDate(allTransactions, startDate, endDate);
        final weeklyData = _groupFeesByWeek(filtered);

        if (weeklyData.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service Charges Over Time',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxFees(weeklyData) * 1.2,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.grey[800]!,
                          tooltipRoundedRadius: 8,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= weeklyData.length) {
                                return const Text('');
                              }
                              final weekData = weeklyData[value.toInt()];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('MMM dd').format(weekData['date'] as DateTime),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toStringAsFixed(0),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: weeklyData.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value['fees'] as double,
                              color: Colors.orange,
                              width: 12,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildTopReceivers(String startDate, String endDate) {
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return transactionsAsync.when(
      data: (allTransactions) {
        final filtered = _filterTransactionsByDate(allTransactions, startDate, endDate);
        final topReceivers = _getTopReceivers(filtered);

        if (topReceivers.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Receivers',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                ...topReceivers.take(5).map((receiver) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            receiver['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          'ETB ${(receiver['amount'] as double).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  List<TransactionEntity> _filterTransactionsByDate(
    List<TransactionEntity> transactions,
    String startDate,
    String endDate,
  ) {
    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate).add(const Duration(days: 1));

    return transactions.where((tx) {
      final txDate = DateTime.parse(tx.createdAt);
      return txDate.isAfter(start.subtract(const Duration(days: 1))) &&
             txDate.isBefore(end);
    }).toList();
  }

  double _calculateTotal(List<TransactionEntity> transactions, {required bool isCredit}) {
    return transactions
        .where((tx) {
          if (isCredit) {
            return tx.messageType == MessageType.creditDetailed ||
                   tx.messageType == MessageType.creditSimple;
          } else {
            return tx.messageType == MessageType.debitTransfer ||
                   tx.messageType == MessageType.debitSimple;
          }
        })
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double _calculateTotalFees(List<TransactionEntity> transactions) {
    return transactions
        .where((tx) => tx.serviceCharge != null)
        .fold(0.0, (sum, tx) => sum + (tx.serviceCharge ?? 0.0));
  }

  List<Map<String, dynamic>> _groupByMonth(List<TransactionEntity> transactions) {
    final Map<String, Map<String, double>> monthly = {};

    for (final tx in transactions) {
      final date = DateTime.parse(tx.createdAt);
      final monthKey = '${date.year}-${date.month}';

      if (!monthly.containsKey(monthKey)) {
        monthly[monthKey] = {'income': 0.0, 'expense': 0.0};
      }

      final isCredit = tx.messageType == MessageType.creditDetailed ||
                       tx.messageType == MessageType.creditSimple;

      if (isCredit) {
        monthly[monthKey]!['income'] = monthly[monthKey]!['income']! + tx.amount;
      } else {
        monthly[monthKey]!['expense'] = monthly[monthKey]!['expense']! + tx.amount;
      }
    }

    return monthly.entries.map((entry) {
      final parts = entry.key.split('-');
      return {
        'date': DateTime(int.parse(parts[0]), int.parse(parts[1])),
        'income': entry.value['income']!,
        'expense': entry.value['expense']!,
      };
    }).toList()
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
  }

  List<Map<String, dynamic>> _calculateBalanceOverTime(List<TransactionEntity> transactions) {
    final sorted = List<TransactionEntity>.from(transactions)
      ..sort((a, b) => DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt)));

    double balance = 0.0;
    final List<Map<String, dynamic>> result = [];

    for (final tx in sorted) {
      final isCredit = tx.messageType == MessageType.creditDetailed ||
                       tx.messageType == MessageType.creditSimple;

      if (isCredit) {
        balance += tx.amount;
      } else {
        balance -= tx.amount;
      }

      if (tx.balanceAfter != null) {
        balance = tx.balanceAfter!;
      }

      result.add({
        'date': DateTime.parse(tx.createdAt),
        'balance': balance,
      });
    }

    return result;
  }

  List<Map<String, dynamic>> _groupFeesByWeek(List<TransactionEntity> transactions) {
    final Map<String, double> weekly = {};

    for (final tx in transactions) {
      if (tx.serviceCharge == null) continue;

      final date = DateTime.parse(tx.createdAt);
      final weekStart = date.subtract(Duration(days: date.weekday - 1));
      final weekKey = '${weekStart.year}-${weekStart.month}-${weekStart.day}';

      weekly[weekKey] = (weekly[weekKey] ?? 0.0) + (tx.serviceCharge ?? 0.0);
    }

    return weekly.entries.map((entry) {
      final parts = entry.key.split('-');
      return {
        'date': DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])),
        'fees': entry.value,
      };
    }).toList()
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
  }

  List<Map<String, dynamic>> _getTopReceivers(List<TransactionEntity> transactions) {
    final Map<String, double> receiverTotals = {};

    for (final tx in transactions) {
      if (tx.receiver != null && tx.messageType == MessageType.debitTransfer) {
        receiverTotals[tx.receiver!] = (receiverTotals[tx.receiver!] ?? 0.0) + tx.amount;
      }
    }

    return receiverTotals.entries.map((entry) {
      return {
        'name': entry.key,
        'amount': entry.value,
      };
    }).toList()
      ..sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
  }

  double _getMaxValue(List<Map<String, dynamic>> monthlyData) {
    if (monthlyData.isEmpty) return 1000.0;
    double max = 0.0;
    for (final data in monthlyData) {
      final income = data['income'] as double? ?? 0.0;
      final expense = data['expense'] as double? ?? 0.0;
      max = max > income ? max : income;
      max = max > expense ? max : expense;
    }
    return max;
  }

  double _getMaxBalance(List<Map<String, dynamic>> balanceData) {
    if (balanceData.isEmpty) return 1000.0;
    return balanceData.map((d) => d['balance'] as double).reduce((a, b) => a > b ? a : b);
  }

  double _getMaxFees(List<Map<String, dynamic>> feesData) {
    if (feesData.isEmpty) return 100.0;
    return feesData.map((d) => d['fees'] as double).reduce((a, b) => a > b ? a : b);
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
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
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
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

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
