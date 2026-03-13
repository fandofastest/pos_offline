import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TransactionRepositoryImpl(db);
});

final transactionFilterProvider = StateProvider<DateTimeRangeFilter>((ref) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  return DateTimeRangeFilter(start: start, end: now);
});

class DateTimeRangeFilter {
  const DateTimeRangeFilter({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  DateTimeRangeFilter copyWith({DateTime? start, DateTime? end}) {
    return DateTimeRangeFilter(start: start ?? this.start, end: end ?? this.end);
  }
}

final transactionsProvider = FutureProvider<List<SaleTransaction>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final f = ref.watch(transactionFilterProvider);
  return repo.getTransactions(start: f.start, end: f.end);
});

final transactionItemsProvider = FutureProvider.family<List<SaleTransactionItem>, int>((ref, id) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getItems(id);
});

final transactionByIdProvider = FutureProvider.family<SaleTransaction?, int>((ref, id) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getTransactionById(id);
});
