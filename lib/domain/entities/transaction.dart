class SaleTransaction {
  const SaleTransaction({
    required this.id,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.cashReceived,
    required this.change,
    required this.createdAt,
  });

  final int? id;
  final double subtotal;
  final double tax;
  final double total;
  final String paymentMethod;
  final double cashReceived;
  final double change;
  final DateTime createdAt;
}

class SaleTransactionItem {
  const SaleTransactionItem({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.quantity,
    required this.price,
  });

  final int? id;
  final int transactionId;
  final int productId;
  final double quantity;
  final double price;
}
