import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/transaction_repository.dart';

class TransactionCsvExporter {
  TransactionCsvExporter({required this.txRepo, required this.productRepo});

  final TransactionRepository txRepo;
  final ProductRepository productRepo;

  final _dtFmt = DateFormat('yyyy-MM-dd HH:mm:ss');

  Future<File> export({required DateTime start, required DateTime end}) async {
    final txs = await txRepo.getTransactions(start: start, end: end);

    final rows = <List<dynamic>>[];
    rows.add([
      'transaction_id',
      'created_at',
      'payment_method',
      'subtotal',
      'tax',
      'total',
      'cash_received',
      'change',
      'product_id',
      'product_name',
      'quantity',
      'price',
      'line_total',
    ]);

    for (final tx in txs) {
      final items = await txRepo.getItems(tx.id!);
      for (final it in items) {
        final pdt = await productRepo.getById(it.productId);
        final name = pdt?.name ?? 'Product #${it.productId}';
        rows.add([
          tx.id,
          _dtFmt.format(tx.createdAt),
          tx.paymentMethod,
          tx.subtotal,
          tx.tax,
          tx.total,
          tx.cashReceived,
          tx.change,
          it.productId,
          name,
          it.quantity,
          it.price,
          it.quantity * it.price,
        ]);
      }
    }

    final csv = const ListToCsvConverter().convert(rows);

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'transactions_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final file = File(p.join(dir.path, fileName));
    await file.writeAsString(csv);
    return file;
  }
}
