import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/export/transaction_csv_exporter.dart';
import '../providers/catalog_providers.dart';
import '../providers/transaction_providers.dart';
import '../widgets/pos_app_bar.dart';
import 'receipt_page.dart';

class TransactionHistoryPage extends ConsumerWidget {
  const TransactionHistoryPage({super.key});

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
    final f = ref.watch(transactionFilterProvider);
    final txsAsync = ref.watch(transactionsProvider);
    final fmt = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: PosAppBar(
        title: 'Transaction History',
        subtitle: 'View all transactions',
        actions: [
          IconButton(
            tooltip: 'Pick date range',
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDateRange: DateTimeRange(start: f.start, end: f.end),
              );
              if (picked == null) return;
              ref.read(transactionFilterProvider.notifier).state = DateTimeRangeFilter(
                start: picked.start,
                end: DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
              );
              ref.invalidate(transactionsProvider);
            },
            icon: const Icon(Icons.date_range),
          ),
          IconButton(
            tooltip: 'Export CSV',
            onPressed: () async {
              try {
                final exporter = TransactionCsvExporter(
                  txRepo: ref.read(transactionRepositoryProvider),
                  productRepo: ref.read(productRepositoryProvider),
                );
                final file = await exporter.export(start: f.start, end: f.end);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('CSV saved: ${file.path}')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export failed: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.download),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(transactionsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'From: ${DateFormat('yyyy-MM-dd').format(f.start)}\nTo: ${DateFormat('yyyy-MM-dd').format(f.end)}',
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: txsAsync.when(
                data: (items) {
                  if (items.isEmpty) return const Center(child: Text('No transactions'));
                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (context, index) {
                      final tx = items[index];
                      final payment = tx.paymentMethod.trim().isEmpty ? 'Cash' : tx.paymentMethod;
                      final isCash = payment.toLowerCase().contains('cash');
                      final badgeBg = isCash ? const Color(0xFFE8F7ED) : const Color(0xFFEFF6FF);
                      final badgeFg = isCash ? const Color(0xFF16A34A) : Theme.of(context).colorScheme.primary;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: _shadowCard(
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => ReceiptPage(transactionId: tx.id!)),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              _txnLabel(tx.id ?? 0),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(fontWeight: FontWeight.w900),
                                            ),
                                            const SizedBox(width: 10),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: badgeBg,
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                isCash ? 'Cash' : 'Card',
                                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                      color: badgeFg,
                                                      fontWeight: FontWeight.w900,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          fmt.format(tx.createdAt),
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${(tx.id ?? 0) > 0 ? 1 : 0} item(s)',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '\$${tx.total.toStringAsFixed(2)}',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        isCash ? 'Cash' : 'Card',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.chevron_right, color: Colors.black.withValues(alpha: 0.35)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: items.length,
                  );
                },
                error: (e, st) => Center(child: Text('Error: $e')),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
