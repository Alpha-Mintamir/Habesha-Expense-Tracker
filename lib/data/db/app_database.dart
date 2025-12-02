import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/constants/db_constants.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  static Database? _database;

  factory AppDatabase() {
    return _instance;
  }

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), DbConstants.dbName);
    return await openDatabase(
      path,
      version: DbConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create categories table
    await db.execute('''
      CREATE TABLE ${DbConstants.tableCategories} (
        ${DbConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colName} TEXT NOT NULL UNIQUE,
        ${DbConstants.colIsDefault} INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colCreatedAt} TEXT NOT NULL
      )
    ''');

    // Create transactions table
    await db.execute('''
      CREATE TABLE ${DbConstants.tableTransactions} (
        ${DbConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colMessageType} TEXT NOT NULL,
        ${DbConstants.colAmount} REAL NOT NULL,
        ${DbConstants.colSender} TEXT,
        ${DbConstants.colReceiver} TEXT,
        ${DbConstants.colServiceCharge} REAL,
        ${DbConstants.colVat} REAL,
        ${DbConstants.colRefNo} TEXT,
        ${DbConstants.colReceiptLink} TEXT,
        ${DbConstants.colBalanceAfter} REAL,
        ${DbConstants.colDate} TEXT NOT NULL,
        ${DbConstants.colTime} TEXT NOT NULL,
        ${DbConstants.colCategoryId} INTEGER,
        ${DbConstants.colCreatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DbConstants.colCategoryId}) REFERENCES ${DbConstants.tableCategories}(${DbConstants.colId}) ON DELETE SET NULL
      )
    ''');

    // Create indexes
    await db.execute('''
      CREATE INDEX idx_transactions_date ON ${DbConstants.tableTransactions}(${DbConstants.colDate})
    ''');
    await db.execute('''
      CREATE INDEX idx_transactions_category ON ${DbConstants.tableTransactions}(${DbConstants.colCategoryId})
    ''');
    await db.execute('''
      CREATE INDEX idx_transactions_message_type ON ${DbConstants.tableTransactions}(${DbConstants.colMessageType})
    ''');

    // Insert default categories
    final defaultCategories = [
      'Income',
      'Transfer Out',
      'Bills',
      'Service Charges',
      'Shopping',
      'Food',
      'Transport',
      'Other',
    ];

    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    for (final categoryName in defaultCategories) {
      batch.insert(
        DbConstants.tableCategories,
        {
          DbConstants.colName: categoryName,
          DbConstants.colIsDefault: 1,
          DbConstants.colCreatedAt: now,
        },
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    // For now, we'll just recreate if version changes
    if (oldVersion < newVersion) {
      // Future migration logic can be added here
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

