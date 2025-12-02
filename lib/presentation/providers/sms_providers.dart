import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/sms_ingestion_service.dart';
import '../../core/services/permission_service.dart';
import '../../data/models/transaction_entity.dart';

/// SMS Ingestion Service provider
final smsIngestionServiceProvider = Provider<SmsIngestionService>((ref) {
  final service = SmsIngestionService();
  
  // Auto-dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// SMS permissions status provider
final smsPermissionsProvider = FutureProvider<bool>((ref) async {
  return await PermissionService.hasSmsPermissions();
});

/// Last parsed transaction provider (for debug/verification)
final lastParsedTransactionProvider = StreamProvider<TransactionEntity>((ref) {
  final service = ref.watch(smsIngestionServiceProvider);
  return service.parsedTransactionStream;
});

/// SMS ingestion errors provider
final smsErrorsProvider = StreamProvider<String>((ref) {
  final service = ref.watch(smsIngestionServiceProvider);
  return service.errorStream;
});

/// SMS ingestion status provider
final smsIngestionStatusProvider = StateProvider<bool>((ref) => false);





