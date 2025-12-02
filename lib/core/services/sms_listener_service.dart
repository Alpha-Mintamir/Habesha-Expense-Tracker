import 'dart:async';
import 'package:telephony_fix/telephony.dart';

/// Service that listens to incoming SMS messages and filters for CBE messages
class SmsListenerService {
  final Telephony _telephony = Telephony.instance;
  final StreamController<SmsMessage> _smsController = StreamController<SmsMessage>.broadcast();

  /// Stream of incoming SMS messages (filtered for CBE)
  Stream<SmsMessage> get smsStream => _smsController.stream;

  /// CBE sender IDs/patterns to filter (common Ethiopian bank SMS sender formats)
  /// You may need to adjust these based on actual CBE sender IDs
  static const List<String> _cbeSenderPatterns = [
    'CBE',
    'Commercial Bank',
    'Commercial Bank of Ethiopia',
  ];

  /// Keywords that indicate a CBE transaction SMS
  static const List<String> _cbeKeywords = [
    'Dear',
    'Account',
    'Credited',
    'debited',
    'Current Balance',
    'Thank you for Banking with CBE',
  ];

  /// Start listening to incoming SMS messages
  Future<bool> startListening() async {
    try {
      // Listen to incoming SMS
      _telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          print('SMS listener callback triggered');
          if (isCbeMessage(message)) {
            print('CBE message confirmed, adding to stream');
            _smsController.add(message);
          } else {
            print('SMS filtered out (not CBE)');
          }
        },
        listenInBackground: true,
      );
      print('SMS listener started successfully');
      return true;
    } catch (e) {
      print('Error starting SMS listener: $e');
      return false;
    }
  }
  
  /// Read recent SMS messages from inbox (fallback method)
  Future<List<SmsMessage>> readRecentSms({int limit = 50}) async {
    try {
      final messages = await _telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );
      // Limit manually if needed
      return messages.take(limit).toList();
    } catch (e) {
      print('Error reading SMS inbox: $e');
      return [];
    }
  }
  
  /// Scan recent SMS messages for CBE transactions
  Future<void> scanRecentSms() async {
    try {
      final messages = await readRecentSms(limit: 100);
      print('Scanning ${messages.length} recent SMS messages...');
      int cbeFound = 0;
      for (final message in messages) {
        if (isCbeMessage(message)) {
          cbeFound++;
          _smsController.add(message);
        }
      }
      print('Found $cbeFound CBE messages in recent SMS');
    } catch (e) {
      print('Error scanning recent SMS: $e');
    }
  }

  /// Stop listening to SMS messages
  void stopListening() {
    // The telephony_fix plugin does not expose a handle to cancel listenIncomingSms,
    // so this is currently a no-op for the underlying listener.
  }

  /// Check if an SMS message is from CBE
  bool isCbeMessage(SmsMessage message) {
    final body = message.body?.toLowerCase() ?? '';
    final sender = message.address?.toLowerCase() ?? '';

    // Debug: Log all incoming SMS for troubleshooting
    print('SMS received - Sender: $sender, Body preview: ${body.substring(0, body.length > 50 ? 50 : body.length)}...');

    // Check sender patterns (more flexible)
    for (final pattern in _cbeSenderPatterns) {
      if (sender.contains(pattern.toLowerCase())) {
        print('CBE message detected by sender pattern: $pattern');
        return true;
      }
    }

    // Check for CBE keywords in message body (reduced threshold to 2 keywords)
    int keywordMatches = 0;
    final matchedKeywords = <String>[];
    for (final keyword in _cbeKeywords) {
      if (body.contains(keyword.toLowerCase())) {
        keywordMatches++;
        matchedKeywords.add(keyword);
      }
    }

    // If at least 2 keywords match, likely a CBE message (reduced from 3)
    if (keywordMatches >= 2) {
      print('CBE message detected by keywords ($keywordMatches): ${matchedKeywords.join(", ")}');
      return true;
    }

    return false;
  }

  /// Dispose resources
  void dispose() {
    stopListening();
    _smsController.close();
  }
}

