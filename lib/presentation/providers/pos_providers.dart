import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../presentation/providers/app_providers.dart';
import '../providers/catalog_providers.dart';
import '../providers/transaction_providers.dart';

final posCartProvider = StateNotifierProvider<PosCartNotifier, PosCartState>((ref) {
  final productRepo = ref.watch(productRepositoryProvider);
  final txRepo = ref.watch(transactionRepositoryProvider);
  final taxRate = ref.watch(taxRateProvider);
  final lowStockThreshold = ref.watch(lowStockThresholdProvider);
  return PosCartNotifier(
    productRepo: productRepo,
    txRepo: txRepo,
    taxRate: taxRate,
    lowStockThreshold: lowStockThreshold,
  );
});

class PosCartNotifier extends StateNotifier<PosCartState> {
  PosCartNotifier({
    required ProductRepository productRepo,
    required TransactionRepository txRepo,
    required double taxRate,
    required int lowStockThreshold,
  })  : _productRepo = productRepo,
        _txRepo = txRepo,
        _taxRate = taxRate,
        _lowStockThreshold = lowStockThreshold,
        super(const PosCartState(items: []));

  final ProductRepository _productRepo;
  final TransactionRepository _txRepo;
  final double _taxRate;
  final int _lowStockThreshold;

  void clear() {
    state = const PosCartState(items: []);
  }

  void addProduct(Product product) {
    final existing = state.items.where((e) => e.product.id == product.id).toList();
    if (existing.isNotEmpty) {
      final item = existing.first;
      setQuantity(productId: product.id!, quantity: item.quantity + 1);
      return;
    }

    state = state.copyWith(
      items: [...state.items, PosCartItem(product: product, quantity: 1)],
    );
  }

  void removeProduct(int productId) {
    state = state.copyWith(items: state.items.where((e) => e.product.id != productId).toList());
  }

  void setQuantity({required int productId, required double quantity}) {
    final q = quantity < 0 ? 0.0 : quantity;
    final updated = state.items
        .map((e) => e.product.id == productId ? e.copyWith(quantity: q) : e)
        .where((e) => e.quantity > 0)
        .toList();
    state = state.copyWith(items: updated);
  }

  double get subtotal {
    return state.items.fold(0, (sum, e) => sum + (e.product.price * e.quantity));
  }

  double get tax {
    return subtotal * _taxRate;
  }

  double get total {
    return subtotal + tax;
  }

  Future<CheckoutResult> checkoutCash({required double cashReceived}) async {
    if (state.items.isEmpty) {
      throw Exception('Cart is empty');
    }

    final computedSubtotal = subtotal;
    final computedTax = tax;
    final t = computedSubtotal + computedTax;
    if (cashReceived < t) {
      throw Exception('Cash received is not enough');
    }

    final change = cashReceived - t;
    final now = DateTime.now();

    final drafts = state.items
        .map(
          (e) => SaleTransactionItemDraft(
            productId: e.product.id!,
            quantity: e.quantity,
            price: e.product.price,
          ),
        )
        .toList(growable: false);

    final txId = await _txRepo.createTransaction(
      subtotal: computedSubtotal,
      tax: computedTax,
      total: t,
      paymentMethod: 'Cash',
      cashReceived: cashReceived,
      change: change,
      createdAt: now,
      items: drafts,
    );

    final lowStockProducts = <Product>[];

    for (final item in state.items) {
      final productId = item.product.id!;
      final current = await _productRepo.getById(productId);
      if (current != null) {
        final remaining = current.stock - item.quantity;
        if (remaining <= _lowStockThreshold) {
          lowStockProducts.add(current.copyWith(stock: remaining));
        }
      }
      await _productRepo.reduceStock(productId: productId, quantity: item.quantity);
    }

    clear();

    return CheckoutResult(
      transactionId: txId,
      subtotal: computedSubtotal,
      tax: computedTax,
      total: t,
      cashReceived: cashReceived,
      change: change,
      lowStockAfterSale: lowStockProducts,
      createdAt: now,
    );
  }
}

class PosCartState {
  const PosCartState({required this.items});

  final List<PosCartItem> items;

  PosCartState copyWith({List<PosCartItem>? items}) {
    return PosCartState(items: items ?? this.items);
  }
}

class PosCartItem {
  const PosCartItem({required this.product, required this.quantity});

  final Product product;
  final double quantity;

  PosCartItem copyWith({Product? product, double? quantity}) {
    return PosCartItem(product: product ?? this.product, quantity: quantity ?? this.quantity);
  }
}

class CheckoutResult {
  const CheckoutResult({
    required this.transactionId,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.cashReceived,
    required this.change,
    required this.lowStockAfterSale,
    required this.createdAt,
  });

  final int transactionId;
  final double subtotal;
  final double tax;
  final double total;
  final double cashReceived;
  final double change;
  final List<Product> lowStockAfterSale;
  final DateTime createdAt;
}
