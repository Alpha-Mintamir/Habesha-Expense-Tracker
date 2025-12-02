import 'dart:async';
import 'package:telephony_fix/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/models/transaction_entity.dart';
import '../sms/sms_parser.dart';
import 'sms_listener_service.dart';

class SmsIngestionService {
  final TransactionRepository _transactionRepository = TransactionRepository();
  final SmsListenerService _smsListener = SmsListenerService();
  StreamSubscription<SmsMessage>? _subscription;
  static const String _lastSyncTimeKey = 'last_sms_sync_time';
  
  /// Get the SMS listener service (for manual scanning)
  SmsListenerService get smsListener => _smsListener;
  
  final StreamController<TransactionEntity> _parsedTransactionController = 
      StreamController<TransactionEntity>.broadcast();
  
  final StreamController<String> _errorController = 
      StreamController<String>.broadcast();

  /// Stream of successfully parsed and saved transactions
  Stream<TransactionEntity> get parsedTransactionStream => 
      _parsedTransactionController.stream;

  /// Stream of errors during parsing/ingestion
  Stream<String> get errorStream => _errorController.stream;

  /// Safely parse the SMS date field from telephony_fix.
  /// telephony_fix typically provides an integer millisSinceEpoch, but we also
  /// handle DateTime and String fallbacks.
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

  /// Start the SMS ingestion pipeline
  Future<bool> start() async {
    try {
      // Start listening to SMS
      final listening = await _smsListener.startListening();
      if (!listening) {
        _errorController.add('Failed to start SMS listener');
        return false;
      }

      // Subscribe to SMS stream
      _subscription = _smsListener.smsStream.listen(
        _processSms,
        onError: (error) {
          _errorController.add('SMS listener error: $error');
        },
      );

      return true;
    } catch (e) {
      _errorController.add('Failed to start ingestion: $e');
      return false;
    }
  }

  /// Stop the SMS ingestion pipeline
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _smsListener.stopListening();
  }
  
  /// Manual sync - only processes NEW SMS messages since last sync
  Future<Map<String, dynamic>> syncNewSms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncTimeStr = prefs.getString(_lastSyncTimeKey);
      DateTime? lastSyncTime;
      
      if (lastSyncTimeStr != null) {
        lastSyncTime = DateTime.parse(lastSyncTimeStr);
      }
      
      // Read recent SMS (limit to 50 for efficiency)
      final messages = await _smsListener.readRecentSms(limit: 50);
      
      int syncedCount = 0;
      int skippedCount = 0;
      
      for (final message in messages) {
        final messageDate = _parseSmsDate(message.date);
        
        // Only process messages newer than last sync
        if (lastSyncTime != null && !messageDate.isAfter(lastSyncTime)) {
          skippedCount++;
          continue;
        }
        
        // Check if it's a CBE message
        if (_smsListener.isCbeMessage(message)) {
          try {
            await _processSms(message);
            syncedCount++;
          } catch (e) {
            // Skip individual message errors
            continue;
          }
        }
      }
      
      // Update last sync time
      final now = DateTime.now();
      await prefs.setString(_lastSyncTimeKey, now.toIso8601String());
      
      return {
        'success': true,
        'synced': syncedCount,
        'skipped': skippedCount,
      };
    } catch (e) {
      _errorController.add('Sync error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'synced': 0,
        'skipped': 0,
      };
    }
  }

  /// Process an incoming SMS message
  Future<void> _processSms(SmsMessage smsMessage) async {
    try {
      final body = smsMessage.body ?? '';
      final DateTime receivedAt = _parseSmsDate(smsMessage.date);

      // Parse the SMS
      final transaction = parseCbeSms(
        body: body,
        receivedAt: receivedAt,
      );

      if (transaction == null) {
        // Not a CBE transaction SMS, ignore silently
        return;
      }

      // Check for duplicates (same ref_no and amount)
      if (await _isDuplicate(transaction)) {
        // Duplicate detected, skip
        return;
      }

      // Save to database
      final id = await _transactionRepository.addFromSms(transaction);
      
      if (id > 0) {
        // Successfully saved, emit to stream
        final savedTransaction = transaction.copyWith(id: id);
        _parsedTransactionController.add(savedTransaction);
      }
    } catch (e) {
      _errorController.add('Error processing SMS: $e');
    }
  }

  /// Check if a transaction is a duplicate (same ref_no and amount)
  Future<bool> _isDuplicate(TransactionEntity transaction) async {
    if (transaction.refNo == null || transaction.refNo!.isEmpty) {
      // No ref_no, can't check for duplicates - allow it
      return false;
    }

    try {
      // Get all transactions with the same ref_no
      final existing = await _transactionRepository.getTransactionsByType(
        transaction.messageType,
      );

      // Check if any existing transaction has same ref_no and amount
      for (final existingTx in existing) {
        if (existingTx.refNo == transaction.refNo &&
            existingTx.amount == transaction.amount) {
          return true;
        }
      }

      return false;
    } catch (e) {
      // If error checking duplicates, allow the transaction
      return false;
    }
  }

  /// Manually process an SMS string (for testing or manual import)
  Future<TransactionEntity?> processSmsString(String body, DateTime receivedAt) async {
    final transaction = parseCbeSms(body: body, receivedAt: receivedAt);
    
    if (transaction == null) {
      return null;
    }

    // Check for duplicates
    if (await _isDuplicate(transaction)) {
      return null;
    }

    // Save to database
    final id = await _transactionRepository.addFromSms(transaction);
    
    if (id > 0) {
      return transaction.copyWith(id: id);
    }

    return null;
  }

  /// Dispose resources
  void dispose() {
    stop();
    _parsedTransactionController.close();
    _errorController.close();
    _smsListener.dispose();
  }
}

