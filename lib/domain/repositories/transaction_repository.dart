import '../entities/transaction.dart';

abstract interface class TransactionRepository {
  Future<int> createTransaction({
    required double subtotal,
    required double tax,
    required double total,
    required String paymentMethod,
    required double cashReceived,
    required double change,
    required DateTime createdAt,
    required List<SaleTransactionItemDraft> items,
  });

  Future<List<SaleTransaction>> getTransactions({DateTime? start, DateTime? end});
  Future<SaleTransaction?> getTransactionById(int id);
  Future<List<SaleTransactionItem>> getItems(int transactionId);
}

class SaleTransactionItemDraft {
  const SaleTransactionItemDraft({
    required this.productId,
    required this.quantity,
    required this.price,
  });

  final int productId;
  final double quantity;
  final double price;
}
