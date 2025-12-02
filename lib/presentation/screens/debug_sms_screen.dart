import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sms_providers.dart';
import '../providers/transaction_providers.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/sms_ingestion_service.dart';

class DebugSmsScreen extends ConsumerStatefulWidget {
  const DebugSmsScreen({super.key});

  @override
  ConsumerState<DebugSmsScreen> createState() => _DebugSmsScreenState();
}

class _DebugSmsScreenState extends ConsumerState<DebugSmsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSmsIngestion();
    });
  }

  Future<void> _initializeSmsIngestion() async {
    final hasPermissions = await PermissionService.hasSmsPermissions();
    if (!hasPermissions) {
      final granted = await PermissionService.requestSmsPermissions();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SMS permissions are required for automatic transaction tracking'),
            ),
          );
        }
        return;
      }
    }

    final service = ref.read(smsIngestionServiceProvider);
    final started = await service.start();
    ref.read(smsIngestionStatusProvider.notifier).state = started;

    if (started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SMS listener started. Waiting for CBE messages...'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissionsStatus = ref.watch(smsPermissionsProvider);
    final ingestionStatus = ref.watch(smsIngestionStatusProvider);
    final lastParsed = ref.watch(lastParsedTransactionProvider);
    final errors = ref.watch(smsErrorsProvider);
    final allTransactions = ref.watch(allTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Debug & Status'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Permissions Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Permissions Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    permissionsStatus.when(
                      data: (granted) => Row(
                        children: [
                          Icon(
                            granted ? Icons.check_circle : Icons.error,
                            color: granted ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(granted ? 'SMS Permissions Granted' : 'SMS Permissions Denied'),
                        ],
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (err, _) => Text('Error: $err'),
                    ),
                    if (permissionsStatus.value == false) ...[
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final granted = await PermissionService.requestSmsPermissions();
                          if (granted) {
                            ref.invalidate(smsPermissionsProvider);
                            await _initializeSmsIngestion();
                          }
                        },
                        child: const Text('Request Permissions'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ingestion Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SMS Ingestion Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          ingestionStatus ? Icons.play_circle : Icons.stop_circle,
                          color: ingestionStatus ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ingestionStatus
                              ? 'Listening for SMS'
                              : 'Not listening',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final service = ref.read(smsIngestionServiceProvider);
                        if (ingestionStatus) {
                          service.stop();
                          ref.read(smsIngestionStatusProvider.notifier).state = false;
                        } else {
                          await _initializeSmsIngestion();
                        }
                      },
                      child: Text(ingestionStatus ? 'Stop Listening' : 'Start Listening'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Manual Scan Button
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manual Actions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final service = ref.read(smsIngestionServiceProvider);
                        await service.smsListener.scanRecentSms();
                        ref.invalidate(allTransactionsProvider);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Scanning recent SMS messages... Check Transactions list.'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Scan Recent SMS'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'If automatic listening doesn\'t work, tap this button to scan your recent SMS inbox for CBE messages.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Last Parsed Transaction
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last Parsed Transaction',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    lastParsed.when(
                      data: (transaction) => transaction == null
                          ? const Text('No transactions parsed yet')
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Type: ${transaction.messageType}'),
                                Text('Amount: ETB ${transaction.amount.toStringAsFixed(2)}'),
                                if (transaction.sender != null)
                                  Text('From: ${transaction.sender}'),
                                if (transaction.receiver != null)
                                  Text('To: ${transaction.receiver}'),
                                Text('Date: ${transaction.date} ${transaction.time}'),
                                if (transaction.refNo != null)
                                  Text('Ref No: ${transaction.refNo}'),
                              ],
                            ),
                      loading: () => const CircularProgressIndicator(),
                      error: (err, _) => Text('Error: $err'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Errors
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Errors',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    errors.when(
                      data: (error) => Text(
                        error,
                        style: const TextStyle(color: Colors.red),
                      ),
                      loading: () => const Text('No errors'),
                      error: (err, _) => Text('Error: $err'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Total Transactions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Database Statistics',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    allTransactions.when(
                      data: (transactions) => Text(
                        'Total Transactions: ${transactions.length}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (err, _) => Text('Error: $err'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

