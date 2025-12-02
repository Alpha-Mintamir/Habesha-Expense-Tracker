class DbConstants {
  // Database
  static const String dbName = 'cbe_expense_tracker.db';
  static const int dbVersion = 1;

  // Table names
  static const String tableTransactions = 'transactions';
  static const String tableCategories = 'categories';

  // Column names - transactions
  static const String colId = 'id';
  static const String colMessageType = 'message_type';
  static const String colAmount = 'amount';
  static const String colSender = 'sender';
  static const String colReceiver = 'receiver';
  static const String colServiceCharge = 'service_charge';
  static const String colVat = 'vat';
  static const String colRefNo = 'ref_no';
  static const String colReceiptLink = 'receipt_link';
  static const String colBalanceAfter = 'balance_after';
  static const String colDate = 'date';
  static const String colTime = 'time';
  static const String colCategoryId = 'category_id';
  static const String colCreatedAt = 'created_at';

  // Column names - categories
  static const String colName = 'name';
  static const String colIsDefault = 'is_default';
}





