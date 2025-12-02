import '../../data/models/transaction_entity.dart';
import '../constants/message_type.dart';

class ParsedSmsException implements Exception {
  final String message;
  ParsedSmsException(this.message);
  @override
  String toString() => 'ParsedSmsException: $message';
}

/// Main entry: try all patterns and return a TransactionEntity or null if not CBE.
TransactionEntity? parseCbeSms({
  required String body,
  required DateTime receivedAt,
}) {
  body = body.trim();

  // Order matters: try most specific first
  return _parseCreditDetailed(body, receivedAt) ??
      _parseDebitTransfer(body, receivedAt) ??
      _parseDebitSimple(body, receivedAt) ??
      _parseCreditSimple(body, receivedAt);
}

/// Helper: Parse amount string (removes commas)
double _parseAmount(String raw) {
  final cleaned = raw.replaceAll(',', '').trim();
  return double.parse(cleaned);
}

/// Helper: Format date from DD/MM/YYYY to YYYY-MM-DD
String _formatDateFromDmy(String dmy) {
  // '23/11/2025' -> '2025-11-23'
  final parts = dmy.split('/');
  if (parts.length != 3) return dmy; // fallback
  final day = parts[0].padLeft(2, '0');
  final month = parts[1].padLeft(2, '0');
  final year = parts[2];
  return '$year-$month-$day';
}

/// Helper: Format DateTime to YYYY-MM-DD
String _formatDate(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Helper: Format DateTime to HH:mm:ss
String _formatTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  final s = dt.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}

/// Helper: Extract receipt link from SMS body
String? _extractReceiptLink(String body) {
  final linkRegex = RegExp(r'https?://\S+',
      caseSensitive: false, multiLine: true);
  final match = linkRegex.firstMatch(body);
  return match?.group(0);
}

/// Helper: Extract Ref No from SMS body
String? _extractRefNoFromBody(String body) {
  // From "Ref No FT25327D1RTS"
  final refRegex =
      RegExp(r'Ref\s*No\s+([A-Z0-9]+)', caseSensitive: false, multiLine: true);
  final m = refRegex.firstMatch(body);
  if (m != null) return m.group(1);

  // From receipt link ?id=FT25327D1RTS01613109
  final linkIdRegex = RegExp(r'\bid=([A-Z0-9]+)\d*', caseSensitive: false);
  final l = linkIdRegex.firstMatch(body);
  return l?.group(1);
}

/// Helper: Build receipt link from Ref No
String? _buildReceiptLinkFromRef(String? refNo) {
  if (refNo == null || refNo.isEmpty) return null;
  // Adjust the suffix "01613109" if needed / make it configurable
  return 'https://apps.cbe.com.et:100/?id=${refNo}01613109';
}

/// Type 1: Detailed Credit (Incoming Transfer)
/// Example: "Dear Alpha your Account 1*********3109 has been Credited with ETB 11,592.03 
/// from Alewi Delil, on 23/11/2025 at 08:04:45 with Ref No FT25327D1RTS 
/// Your Current Balance is ETB 12,122.93."
TransactionEntity? _parseCreditDetailed(
  String body,
  DateTime receivedAt,
) {
  final regex = RegExp(
    r'Dear\s+.+?Account\s+([0-9*]+)\s+has been Credited with ETB\s+([\d,]+\.\d+).*?'
    r'from\s+(.+?),\s+on\s+(\d{2}/\d{2}/\d{4})\s+at\s+(\d{2}:\d{2}:\d{2}).*?'
    r'Ref\s*No\s+([A-Z0-9]+).*?'
    r'Current Balance is ETB\s+([\d,]+\.\d+)',
    caseSensitive: false,
    dotAll: true,
    multiLine: true,
  );

  final m = regex.firstMatch(body);
  if (m == null) return null;

  final amount = _parseAmount(m.group(2)!);
  final sender = m.group(3)!.trim();
  final date = _formatDateFromDmy(m.group(4)!);
  final time = m.group(5)!;
  final refNoInText = m.group(6)!.trim();
  final balanceAfter = _parseAmount(m.group(7)!);

  final refNo = _extractRefNoFromBody(body) ?? refNoInText;
  final receiptLink =
      _extractReceiptLink(body) ?? _buildReceiptLinkFromRef(refNo);

  return TransactionEntity(
    messageType: MessageType.creditDetailed,
    amount: amount,
    sender: sender,
    receiver: null,
    serviceCharge: null,
    vat: null,
    refNo: refNo,
    receiptLink: receiptLink,
    balanceAfter: balanceAfter,
    date: date,
    time: time,
    categoryId: null,
    createdAt: receivedAt.toIso8601String(),
  );
}

/// Type 2: Detailed Debit Transfer (Outgoing Transfer)
/// Example: "Dear Alpha, You have transfered ETB 1,000.00 to Mintamir Awulachew 
/// on 23/11/2025 at 08:06:44 from your account 1*********3109. 
/// Your account has been debited with a S.charge of ETB 0.50 
/// and 15% VAT of ETB0.08, with a total of ETB1000.58. 
/// Your Current Balance is ETB 11,122.35."
TransactionEntity? _parseDebitTransfer(
  String body,
  DateTime receivedAt,
) {
  final regex = RegExp(
    r'Dear\s+.+?You have transfered ETB\s+([\d,]+\.\d+)\s+to\s+(.+?)\s+'
    r'on\s+(\d{2}/\d{2}/\d{4})\s+at\s+(\d{2}:\d{2}:\d{2})\s+from your account\s+([0-9*]+)\.?.*?'
    r'has been debited with a S\.charge of ETB\s+([\d,]+\.\d+)\s*'
    r'and\s+15% VAT of ETB\s*([\d,]+\.\d+),\s*with a total of ETB\s*([\d,]+\.\d+)\.?.*?'
    r'Current Balance is ETB\s+([\d,]+\.\d+)',
    caseSensitive: false,
    dotAll: true,
    multiLine: true,
  );

  final m = regex.firstMatch(body);
  if (m == null) return null;

  final amount = _parseAmount(m.group(1)!);
  final receiver = m.group(2)!.trim();
  final date = _formatDateFromDmy(m.group(3)!);
  final time = m.group(4)!;
  final serviceCharge = _parseAmount(m.group(6)!);
  final vat = _parseAmount(m.group(7)!);
  // total deducted = m.group(8) - not stored separately
  final balanceAfter = _parseAmount(m.group(9)!);

  final refNo = _extractRefNoFromBody(body);
  final receiptLink =
      _extractReceiptLink(body) ?? _buildReceiptLinkFromRef(refNo);

  return TransactionEntity(
    messageType: MessageType.debitTransfer,
    amount: amount,
    sender: null,
    receiver: receiver,
    serviceCharge: serviceCharge,
    vat: vat,
    refNo: refNo,
    receiptLink: receiptLink,
    balanceAfter: balanceAfter,
    date: date,
    time: time,
    categoryId: null,
    createdAt: receivedAt.toIso8601String(),
  );
}

/// Type 3: Simple Debit (ATM, POS, Fees, Service Charges)
/// Example: "Dear Alpha your Account 1*********3109 has been debited with ETB 200.00. 
/// Your Current Balance is ETB 550.22"
TransactionEntity? _parseDebitSimple(
  String body,
  DateTime receivedAt,
) {
  final regex = RegExp(
    r'Dear\s+.+?Account\s+([0-9*]+)\s+has been debited with ETB\s+([\d,]+\.\d+)\.?.*?'
    r'Current Balance is ETB\s+([\d,]+\.\d+)',
    caseSensitive: false,
    dotAll: true,
    multiLine: true,
  );

  final m = regex.firstMatch(body);
  if (m == null) return null;

  final amount = _parseAmount(m.group(2)!);
  final balanceAfter = _parseAmount(m.group(3)!);

  final refNo = _extractRefNoFromBody(body);
  final receiptLink =
      _extractReceiptLink(body) ?? _buildReceiptLinkFromRef(refNo);

  final date = _formatDate(receivedAt);
  final time = _formatTime(receivedAt);

  return TransactionEntity(
    messageType: MessageType.debitSimple,
    amount: amount,
    sender: null,
    receiver: null,
    serviceCharge: null,
    vat: null,
    refNo: refNo,
    receiptLink: receiptLink,
    balanceAfter: balanceAfter,
    date: date,
    time: time,
    categoryId: null,
    createdAt: receivedAt.toIso8601String(),
  );
}

/// Type 4: Simple Credit (Salary, Reversal, Promotions, Refunds)
/// Example: "Dear Alpha your Account 1*********3109 has been Credited with ETB 400.00. 
/// Your Current Balance is ETB 550.77"
TransactionEntity? _parseCreditSimple(
  String body,
  DateTime receivedAt,
) {
  final regex = RegExp(
    r'Dear\s+.+?Account\s+([0-9*]+)\s+has been Credited with ETB\s+([\d,]+\.\d+)\.?.*?'
    r'Current Balance is ETB\s+([\d,]+\.\d+)',
    caseSensitive: false,
    dotAll: true,
    multiLine: true,
  );

  final m = regex.firstMatch(body);
  if (m == null) return null;

  final amount = _parseAmount(m.group(2)!);
  final balanceAfter = _parseAmount(m.group(3)!);

  final refNo = _extractRefNoFromBody(body);
  final receiptLink =
      _extractReceiptLink(body) ?? _buildReceiptLinkFromRef(refNo);

  final date = _formatDate(receivedAt);
  final time = _formatTime(receivedAt);

  return TransactionEntity(
    messageType: MessageType.creditSimple,
    amount: amount,
    sender: null,
    receiver: null,
    serviceCharge: null,
    vat: null,
    refNo: refNo,
    receiptLink: receiptLink,
    balanceAfter: balanceAfter,
    date: date,
    time: time,
    categoryId: null,
    createdAt: receivedAt.toIso8601String(),
  );
}





