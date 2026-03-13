import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(this._db);

  final AppDatabase _db;

  final _fmt = DateFormat('yyyy-MM-ddTHH:mm:ss');

  @override
  Future<int> createTransaction({
    required double subtotal,
    required double tax,
    required double total,
    required String paymentMethod,
    required double cashReceived,
    required double change,
    required DateTime createdAt,
    required List<SaleTransactionItemDraft> items,
  }) async {
    final Database database = await _db.database;

    return database.transaction<int>((txn) async {
      final txId = await txn.insert('transactions', {
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'payment_method': paymentMethod,
        'cash_received': cashReceived,
        'change': change,
        'created_at': _fmt.format(createdAt.toLocal()),
      });

      for (final item in items) {
        await txn.insert('transaction_items', {
          'transaction_id': txId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'price': item.price,
        });
      }

      return txId;
    });
  }

  @override
  Future<List<SaleTransaction>> getTransactions({DateTime? start, DateTime? end}) async {
    final Database database = await _db.database;

    String? where;
    List<Object?>? whereArgs;

    if (start != null && end != null) {
      where = 'created_at >= ? AND created_at <= ?';
      whereArgs = [_fmt.format(start.toLocal()), _fmt.format(end.toLocal())];
    } else if (start != null) {
      where = 'created_at >= ?';
      whereArgs = [_fmt.format(start.toLocal())];
    } else if (end != null) {
      where = 'created_at <= ?';
      whereArgs = [_fmt.format(end.toLocal())];
    }

    final rows = await database.query(
      'transactions',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    return rows
        .map(
          (e) => SaleTransaction(
            id: e['id'] as int,
            subtotal: (e['subtotal'] as num?)?.toDouble() ?? 0,
            tax: (e['tax'] as num?)?.toDouble() ?? 0,
            total: (e['total'] as num).toDouble(),
            paymentMethod: e['payment_method'] as String,
            cashReceived: (e['cash_received'] as num?)?.toDouble() ?? 0,
            change: (e['change'] as num?)?.toDouble() ?? 0,
            createdAt: _fmt.parse(e['created_at'] as String, true).toLocal(),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<SaleTransaction?> getTransactionById(int id) async {
    final Database database = await _db.database;
    final rows = await database.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final e = rows.first;
    return SaleTransaction(
      id: e['id'] as int,
      subtotal: (e['subtotal'] as num?)?.toDouble() ?? 0,
      tax: (e['tax'] as num?)?.toDouble() ?? 0,
      total: (e['total'] as num).toDouble(),
      paymentMethod: e['payment_method'] as String,
      cashReceived: (e['cash_received'] as num?)?.toDouble() ?? 0,
      change: (e['change'] as num?)?.toDouble() ?? 0,
      createdAt: _fmt.parse(e['created_at'] as String, true).toLocal(),
    );
  }

  @override
  Future<List<SaleTransactionItem>> getItems(int transactionId) async {
    final Database database = await _db.database;
    final rows = await database.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
      orderBy: 'id ASC',
    );

    return rows
        .map(
          (e) => SaleTransactionItem(
            id: e['id'] as int,
            transactionId: e['transaction_id'] as int,
            productId: e['product_id'] as int,
            quantity: (e['quantity'] as num).toDouble(),
            price: (e['price'] as num).toDouble(),
          ),
        )
        .toList(growable: false);
  }
}
