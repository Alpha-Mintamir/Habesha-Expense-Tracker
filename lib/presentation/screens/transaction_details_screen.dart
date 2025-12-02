import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/transaction_providers.dart';
import '../../core/constants/message_type.dart';
import 'package:intl/intl.dart';

class TransactionDetailsScreen extends ConsumerWidget {
  final int transactionId;

  const TransactionDetailsScreen({
    super.key,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionAsync = ref.watch(transactionByIdProvider(transactionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
      ),
      body: transactionAsync.when(
        data: (transaction) {
          if (transaction == null) {
            return const Center(child: Text('Transaction not found'));
          }

          final isCredit = transaction.messageType == MessageType.creditDetailed ||
                          transaction.messageType == MessageType.creditSimple;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Amount Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          isCredit ? 'Credit' : 'Debit',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${isCredit ? '+' : '-'} ETB ${transaction.amount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isCredit ? Colors.green : Colors.red,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Transaction Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailRow(
                          label: 'Type',
                          value: _formatMessageType(transaction.messageType),
                        ),
                        const Divider(),
                        if (transaction.sender != null)
                          _DetailRow(
                            label: 'From',
                            value: transaction.sender!,
                          ),
                        if (transaction.sender != null) const Divider(),
                        if (transaction.receiver != null)
                          _DetailRow(
                            label: 'To',
                            value: transaction.receiver!,
                          ),
                        if (transaction.receiver != null) const Divider(),
                        _DetailRow(
                          label: 'Date',
                          value: DateFormat('MMMM dd, yyyy').format(
                            DateTime.parse(transaction.createdAt),
                          ),
                        ),
                        const Divider(),
                        _DetailRow(
                          label: 'Time',
                          value: transaction.time,
                        ),
                        if (transaction.refNo != null) ...[
                          const Divider(),
                          _DetailRow(
                            label: 'Ref No',
                            value: transaction.refNo!,
                          ),
                        ],
                        if (transaction.balanceAfter != null) ...[
                          const Divider(),
                          _DetailRow(
                            label: 'Balance After',
                            value: 'ETB ${transaction.balanceAfter!.toStringAsFixed(2)}',
                          ),
                        ],
                        if (transaction.serviceCharge != null) ...[
                          const Divider(),
                          _DetailRow(
                            label: 'Service Charge',
                            value: 'ETB ${transaction.serviceCharge!.toStringAsFixed(2)}',
                          ),
                        ],
                        if (transaction.vat != null) ...[
                          const Divider(),
                          _DetailRow(
                            label: 'VAT',
                            value: 'ETB ${transaction.vat!.toStringAsFixed(2)}',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Receipt Link
                if (transaction.receiptLink != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Receipt',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final uri = Uri.parse(transaction.receiptLink!);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Could not open receipt link'),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.receipt),
                            label: const Text('View Receipt'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
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
            ],
          ),
        ),
      ),
    );
  }

  String _formatMessageType(String type) {
    switch (type) {
      case MessageType.creditDetailed:
        return 'Credit (Detailed)';
      case MessageType.creditSimple:
        return 'Unknown Credit';
      case MessageType.debitTransfer:
        return 'Debit (Transfer)';
      case MessageType.debitSimple:
        return 'Unknown Debit';
      default:
        return type;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

