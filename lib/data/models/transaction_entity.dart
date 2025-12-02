import '../../core/constants/db_constants.dart';

class TransactionEntity {
  final int? id;
  final String messageType;
  final double amount;
  final String? sender;
  final String? receiver;
  final double? serviceCharge;
  final double? vat;
  final String? refNo;
  final String? receiptLink;
  final double? balanceAfter;
  final String date; // 'yyyy-MM-dd'
  final String time; // 'HH:mm:ss'
  final int? categoryId;
  final String createdAt; // ISO 8601

  TransactionEntity({
    this.id,
    required this.messageType,
    required this.amount,
    this.sender,
    this.receiver,
    this.serviceCharge,
    this.vat,
    this.refNo,
    this.receiptLink,
    this.balanceAfter,
    required this.date,
    required this.time,
    this.categoryId,
    required this.createdAt,
  });

  factory TransactionEntity.fromMap(Map<String, dynamic> map) {
    return TransactionEntity(
      id: map[DbConstants.colId] as int?,
      messageType: map[DbConstants.colMessageType] as String,
      amount: (map[DbConstants.colAmount] as num).toDouble(),
      sender: map[DbConstants.colSender] as String?,
      receiver: map[DbConstants.colReceiver] as String?,
      serviceCharge: map[DbConstants.colServiceCharge] != null
          ? (map[DbConstants.colServiceCharge] as num).toDouble()
          : null,
      vat: map[DbConstants.colVat] != null
          ? (map[DbConstants.colVat] as num).toDouble()
          : null,
      refNo: map[DbConstants.colRefNo] as String?,
      receiptLink: map[DbConstants.colReceiptLink] as String?,
      balanceAfter: map[DbConstants.colBalanceAfter] != null
          ? (map[DbConstants.colBalanceAfter] as num).toDouble()
          : null,
      date: map[DbConstants.colDate] as String,
      time: map[DbConstants.colTime] as String,
      categoryId: map[DbConstants.colCategoryId] as int?,
      createdAt: map[DbConstants.colCreatedAt] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DbConstants.colId: id,
      DbConstants.colMessageType: messageType,
      DbConstants.colAmount: amount,
      DbConstants.colSender: sender,
      DbConstants.colReceiver: receiver,
      DbConstants.colServiceCharge: serviceCharge,
      DbConstants.colVat: vat,
      DbConstants.colRefNo: refNo,
      DbConstants.colReceiptLink: receiptLink,
      DbConstants.colBalanceAfter: balanceAfter,
      DbConstants.colDate: date,
      DbConstants.colTime: time,
      DbConstants.colCategoryId: categoryId,
      DbConstants.colCreatedAt: createdAt,
    };
  }

  TransactionEntity copyWith({
    int? id,
    String? messageType,
    double? amount,
    String? sender,
    String? receiver,
    double? serviceCharge,
    double? vat,
    String? refNo,
    String? receiptLink,
    double? balanceAfter,
    String? date,
    String? time,
    int? categoryId,
    String? createdAt,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      messageType: messageType ?? this.messageType,
      amount: amount ?? this.amount,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      vat: vat ?? this.vat,
      refNo: refNo ?? this.refNo,
      receiptLink: receiptLink ?? this.receiptLink,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      date: date ?? this.date,
      time: time ?? this.time,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

