import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/sms_listener_service.dart';
import '../../core/services/sms_ingestion_service.dart';
import '../../data/repositories/transaction_repository.dart';
import '../providers/sms_providers.dart';
import '../providers/transaction_providers.dart';
import 'package:intl/intl.dart';

enum SyncPeriod {
  oneMonth,
  threeMonths,
  sixMonths,
  twelveMonths,
  all,
}

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback? onComplete;

  const OnboardingScreen({super.key, this.onComplete});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  SyncPeriod _selectedPeriod = SyncPeriod.threeMonths;
  bool _isSyncing = false;
  int _syncedCount = 0;
  String? _error;

  DateTime _getStartDateForPeriod(SyncPeriod period) {
    final now = DateTime.now();
    switch (period) {
      case SyncPeriod.oneMonth:
        return DateTime(now.year, now.month - 1, now.day);
      case SyncPeriod.threeMonths:
        return DateTime(now.year, now.month - 3, now.day);
      case SyncPeriod.sixMonths:
        return DateTime(now.year, now.month - 6, now.day);
      case SyncPeriod.twelveMonths:
        return DateTime(now.year, now.month - 12, now.day);
      case SyncPeriod.all:
        return DateTime(2020, 1, 1); // Arbitrary old date
    }
  }

  DateTime _parseSmsDate(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    if (raw is String) {
      final asInt = int.tryParse(raw);
      if (asInt != null) {
        return DateTime.fromMillisecondsSinceEpoch(asInt);
      }
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  Future<void> _startSync() async {
    setState(() {
      _isSyncing = true;
      _syncedCount = 0;
      _error = null;
    });

    try {
      // Request permissions
      final hasPermissions = await PermissionService.hasSmsPermissions();
      if (!hasPermissions) {
        final granted = await PermissionService.requestSmsPermissions();
        if (!granted) {
          setState(() {
            _error = 'SMS permissions are required to sync past transactions';
            _isSyncing = false;
          });
          return;
        }
      }

      // Get SMS listener service
      final listenerService = SmsListenerService();
      final ingestionService = SmsIngestionService();
      final transactionRepo = TransactionRepository();

      // Read SMS messages
      final startDate = _getStartDateForPeriod(_selectedPeriod);
      final messages = await listenerService.readRecentSms(limit: 1000);

      // Filter by date and process
      int synced = 0;
      for (final message in messages) {
        final messageDate = _parseSmsDate(message.date);

        if (messageDate.isBefore(startDate)) continue;

        if (listenerService.isCbeMessage(message)) {
          try {
            final body = message.body ?? '';
            final transaction = await ingestionService.processSmsString(
              body,
              messageDate,
            );

            if (transaction != null) {
              synced++;
              if (mounted) {
                setState(() {
                  _syncedCount = synced;
                });
              }
            }
          } catch (e) {
            // Skip errors for individual messages
            continue;
          }
        }
      }

      // Invalidate providers to refresh UI
      ref.invalidate(allTransactionsProvider);

      if (mounted) {
        setState(() {
          _isSyncing = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully synced $_syncedCount transactions'),
            backgroundColor: Colors.green,
          ),
        );

        // For first-run flow, let AppWrapper decide what to show next.
        // For Settings → "Resync Past SMS", just pop back.
        if (widget.onComplete != null) {
          widget.onComplete!();
        } else {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error syncing: $e';
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              Text(
              'Welcome to Habesha Expense Tracker',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Sync your past CBE SMS messages to get started. Choose how far back you want to import transactions.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Period Selection
              if (!_isSyncing) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Import Period',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        ...SyncPeriod.values.map((period) {
                          return RadioListTile<SyncPeriod>(
                            title: Text(_getPeriodLabel(period)),
                            value: period,
                            groupValue: _selectedPeriod,
                            onChanged: (value) {
                              setState(() {
                                _selectedPeriod = value!;
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _startSync,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Start Sync'),
                  ),
                ),
              ] else ...[
                // Syncing State
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 24),
                        Text(
                          'Syncing transactions...',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Found $_syncedCount transactions',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _isSyncing = false;
                    });
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getPeriodLabel(SyncPeriod period) {
    switch (period) {
      case SyncPeriod.oneMonth:
        return 'Last 1 month';
      case SyncPeriod.threeMonths:
        return 'Last 3 months';
      case SyncPeriod.sixMonths:
        return 'Last 6 months';
      case SyncPeriod.twelveMonths:
        return 'Last 12 months';
      case SyncPeriod.all:
        return 'All available messages';
    }
  }
}

