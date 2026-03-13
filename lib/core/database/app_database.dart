import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'pos_offline.db';
  static const _dbVersion = 2;

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    final created = await _open();
    _db = created;
    return created;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createTables(db);
        await _seed(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE transactions ADD COLUMN subtotal REAL NOT NULL DEFAULT 0');
          await db.execute('ALTER TABLE transactions ADD COLUMN tax REAL NOT NULL DEFAULT 0');
          await db.execute('ALTER TABLE transactions ADD COLUMN cash_received REAL NOT NULL DEFAULT 0');
          await db.execute('ALTER TABLE transactions ADD COLUMN change REAL NOT NULL DEFAULT 0');
        }
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  role TEXT NOT NULL
);
''');

    await db.execute('''
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE
);
''');

    await db.execute('''
CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  barcode TEXT,
  category_id INTEGER,
  price REAL NOT NULL,
  stock REAL NOT NULL,
  unit TEXT NOT NULL,
  FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
);
''');

    await db.execute('''
CREATE TABLE transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  subtotal REAL NOT NULL,
  tax REAL NOT NULL,
  total REAL NOT NULL,
  payment_method TEXT NOT NULL,
  cash_received REAL NOT NULL,
  change REAL NOT NULL,
  created_at TEXT NOT NULL
);
''');

    await db.execute('''
CREATE TABLE transaction_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  quantity REAL NOT NULL,
  price REAL NOT NULL,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id)
);
''');

    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode);');
    await db.execute('CREATE INDEX idx_transactions_created_at ON transactions(created_at);');
    await db.execute('CREATE INDEX idx_items_transaction_id ON transaction_items(transaction_id);');
  }

  Future<void> _seed(Database db) async {
    final adminHash = _sha256('admin');
    final cashierHash = _sha256('cashier');

    await db.insert('users', {
      'username': 'admin',
      'password': adminHash,
      'role': 'admin',
    });

    await db.insert('users', {
      'username': 'cashier',
      'password': cashierHash,
      'role': 'cashier',
    });
  }

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) return;
    await db.close();
    _db = null;
  }
}
