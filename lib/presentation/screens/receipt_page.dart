import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/product.dart';
import '../../domain/entities/transaction.dart';
import '../providers/catalog_providers.dart';
import '../providers/transaction_providers.dart';
import '../widgets/pos_app_bar.dart';

class ReceiptPage extends ConsumerWidget {
  const ReceiptPage({super.key, required this.transactionId});

  final int transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionByIdProvider(transactionId));
    final itemsAsync = ref.watch(transactionItemsProvider(transactionId));

    return Scaffold(
      appBar: const PosAppBar(
        title: 'Receipt',
        subtitle: 'Transaction details',
      ),
      body: SafeArea(
        child: txAsync.when(
          data: (tx) {
            if (tx == null) return const Center(child: Text('Transaction not found'));
            return itemsAsync.when(
              data: (items) => _ReceiptView(tx: tx, items: items),
              error: (e, st) => Center(child: Text('Error: $e')),
              loading: () => const Center(child: CircularProgressIndicator()),
            );
          },
          error: (e, st) => Center(child: Text('Error: $e')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _ReceiptView extends ConsumerWidget {
  const _ReceiptView({required this.tx, required this.items});

  final SaleTransaction tx;
  final List<SaleTransactionItem> items;

  Widget _shadowCard({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Card(child: child),
    );
  }

  String _txnLabel(int id) {
    return 'TXN${id.toString().padLeft(4, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productRepo = ref.watch(productRepositoryProvider);
    final fmt = DateFormat('yyyy-MM-dd HH:mm');

    return FutureBuilder<List<_ReceiptLine>>(
      future: () async {
        final lines = <_ReceiptLine>[];
        for (final it in items) {
          final Product? p = await productRepo.getById(it.productId);
          lines.add(_ReceiptLine(
            name: p?.name ?? 'Product #${it.productId}',
            qty: it.quantity,
            price: it.price,
            lineTotal: it.quantity * it.price,
          ));
        }
        return lines;
      }(),
      builder: (context, snapshot) {
        final lines = snapshot.data ?? const <_ReceiptLine>[];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _shadowCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.receipt_long_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Receipt',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Transaction details',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _txnLabel(tx.id ?? 0),
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Date: ${fmt.format(tx.createdAt)}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _shadowCard(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text('Items', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                        const Spacer(),
                        if (snapshot.connectionState != ConnectionState.done)
                          const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    if (lines.isEmpty && snapshot.connectionState == ConnectionState.done)
                      const Padding(
                        padding: EdgeInsets.all(14),
                        child: Align(alignment: Alignment.centerLeft, child: Text('No items')),
                      )
                    else
                      ...lines.map(
                        (l) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  l.name,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${l.qty.toStringAsFixed(0)} x \$${l.price.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 90,
                                child: Text(
                                  '\$${l.lineTotal.toStringAsFixed(2)}',
                                  textAlign: TextAlign.end,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _shadowCard(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text('Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F7ED),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            tx.paymentMethod.trim().isEmpty ? 'Cash' : tx.paymentMethod,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: const Color(0xFF16A34A),
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    _TotalRow(label: 'Subtotal', value: tx.subtotal),
                    _TotalRow(label: 'Tax', value: tx.tax),
                    _TotalRow(label: 'Total', value: tx.total, isBold: true),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    _TotalRow(label: 'Cash received', value: tx.cashReceived),
                    _TotalRow(label: 'Change', value: tx.change),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Thank you',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value, this.isBold = false});

  final String label;
  final double value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final style = isBold ? Theme.of(context).textTheme.titleMedium : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value.toStringAsFixed(2), style: style),
        ],
      ),
    );
  }
}

class _ReceiptLine {
  const _ReceiptLine({required this.name, required this.qty, required this.price, required this.lineTotal});

  final String name;
  final double qty;
  final double price;
  final double lineTotal;
}


