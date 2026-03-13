import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../providers/catalog_providers.dart';
import '../providers/pos_providers.dart';
import '../widgets/pos_app_bar.dart';
import 'barcode_scanner_page.dart';
import 'receipt_page.dart';

final _posSelectedCategoryIdProvider = StateProvider<int?>((ref) => null);

class PosPage extends ConsumerWidget {
  const PosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final query = ref.watch(productQueryProvider);
    final cart = ref.watch(posCartProvider);
    final cartNotifier = ref.read(posCartProvider.notifier);

    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategoryId = ref.watch(_posSelectedCategoryIdProvider);

    final wide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: PosAppBar(
        title: 'Point of Sale',
        subtitle: 'Select products to add to cart',
        actions: [
          IconButton(
            tooltip: 'Scan barcode',
            onPressed: () async {
              final code = await Navigator.of(context).push<String>(
                MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
              );
              if (code == null) return;
              final p = await ref.read(productRepositoryProvider).getByBarcode(code);
              if (p == null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Product not found for barcode: $code')),
                  );
                }
                return;
              }
              cartNotifier.addProduct(p);
            },
            icon: const Icon(Icons.qr_code_scanner),
          ),
          IconButton(
            tooltip: 'Clear cart',
            onPressed: cart.items.isEmpty
                ? null
                : () {
                    cartNotifier.clear();
                  },
            icon: const Icon(Icons.delete_sweep),
          ),
        ],
      ),
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _ProductsPane(
                      productsAsync: productsAsync,
                      categoriesAsync: categoriesAsync,
                      query: query,
                      selectedCategoryId: selectedCategoryId,
                      onCategoryChanged: (v) => ref.read(_posSelectedCategoryIdProvider.notifier).state = v,
                      onQueryChanged: (v) => ref.read(productQueryProvider.notifier).state = v,
                      onAdd: (p) => cartNotifier.addProduct(p),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    flex: 2,
                    child: _CartPane(cart: cart),
                  ),
                ],
              )
            : Column(
                children: [
                  Expanded(
                    child: _ProductsPane(
                      productsAsync: productsAsync,
                      categoriesAsync: categoriesAsync,
                      query: query,
                      selectedCategoryId: selectedCategoryId,
                      onCategoryChanged: (v) => ref.read(_posSelectedCategoryIdProvider.notifier).state = v,
                      onQueryChanged: (v) => ref.read(productQueryProvider.notifier).state = v,
                      onAdd: (p) => cartNotifier.addProduct(p),
                    ),
                  ),
                  const Divider(height: 1),
                  SizedBox(height: 320, child: _CartPane(cart: cart)),
                ],
              ),
      ),
      bottomNavigationBar: _CheckoutBar(
        cart: cart,
        onCheckout: () async {
          if (cart.items.isEmpty) return;
          final cash = await showDialog<double>(
            context: context,
            builder: (_) => const _CashDialog(),
          );
          if (cash == null) return;

          try {
            final result = await cartNotifier.checkoutCash(cashReceived: cash);

            if (context.mounted) {
              if (result.lowStockAfterSale.isNotEmpty) {
                final names = result.lowStockAfterSale.map((e) => '${e.name} (${e.stock.toStringAsFixed(2)})').join(', ');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Low stock: $names')),
                );
              }

              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ReceiptPage(transactionId: result.transactionId)),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checkout failed: $e')));
            }
          }
        },
      ),
    );
  }
}

class _ProductsPane extends StatefulWidget {
  const _ProductsPane({
    required this.productsAsync,
    required this.categoriesAsync,
    required this.query,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.onQueryChanged,
    required this.onAdd,
  });

  final AsyncValue<List<Product>> productsAsync;
  final AsyncValue<List<Category>> categoriesAsync;
  final String query;
  final int? selectedCategoryId;
  final ValueChanged<int?> onCategoryChanged;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Product> onAdd;

  @override
  State<_ProductsPane> createState() => _ProductsPaneState();
}

class _ProductsPaneState extends State<_ProductsPane> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _ProductsPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query && _controller.text != widget.query) {
      _controller.text = widget.query;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: _shadowCard(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search products...',
                border: InputBorder.none,
              ),
              onChanged: widget.onQueryChanged,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: widget.categoriesAsync.when(
            data: (cats) {
              final theme = Theme.of(context);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _CategoryChip(
                      label: 'All',
                      selected: widget.selectedCategoryId == null,
                      onTap: () => widget.onCategoryChanged(null),
                    ),
                    const SizedBox(width: 8),
                    ...cats.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _CategoryChip(
                          label: c.name,
                          selected: widget.selectedCategoryId == c.id,
                          onTap: () => widget.onCategoryChanged(c.id),
                        ),
                      ),
                    ),
                    if (cats.isEmpty)
                      Text(
                        'No categories',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              );
            },
            error: (e, st) => const SizedBox.shrink(),
            loading: () => const SizedBox(
              height: 38,
              child: Center(child: LinearProgressIndicator(minHeight: 2)),
            ),
          ),
        ),
        Expanded(
          child: widget.productsAsync.when(
            data: (items) {
              final filtered = widget.selectedCategoryId == null
                  ? items
                  : items.where((p) => p.categoryId == widget.selectedCategoryId).toList();

              if (filtered.isEmpty) return const Center(child: Text('No products'));

              return LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final crossAxisCount = w >= 900
                      ? 5
                      : w >= 700
                          ? 4
                          : w >= 500
                              ? 3
                              : 2;

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.78,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final p = filtered[index];
                      return InkWell(
                        onTap: () => widget.onAdd(p),
                        borderRadius: BorderRadius.circular(18),
                        child: _shadowCard(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    height: 108,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
                                          Colors.black.withValues(alpha: 0.02),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.inventory_2_outlined,
                                      size: 34,
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  p.name,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '\$${p.price.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Stock: ${p.stock.toStringAsFixed(0)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
            error: (e, st) => Center(child: Text('Error: $e')),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }
}

class _CartPane extends ConsumerWidget {
  const _CartPane({required this.cart});

  final PosCartState cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(posCartProvider.notifier);
    final subtotal = notifier.subtotal;
    final tax = notifier.tax;
    final total = notifier.total;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text('Cart', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              Text('${cart.items.length} items'),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: cart.items.isEmpty
              ? const Center(child: Text('Empty cart'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return ListTile(
                      title: Text(item.product.name),
                      subtitle: Text('Price: ${item.product.price.toStringAsFixed(2)}'),
                      trailing: SizedBox(
                        width: 220,
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => notifier.setQuantity(
                                productId: item.product.id!,
                                quantity: item.quantity - 1,
                              ),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Expanded(
                              child: Text(
                                item.quantity.toStringAsFixed(0),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              onPressed: () => notifier.setQuantity(
                                productId: item.product.id!,
                                quantity: item.quantity + 1,
                              ),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            IconButton(
                              onPressed: () => notifier.removeProduct(item.product.id!),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: cart.items.length,
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _TotalRow(label: 'Subtotal', value: subtotal),
              _TotalRow(label: 'Tax', value: tax),
              _TotalRow(label: 'Total', value: total, bold: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value, this.bold = false});

  final String label;
  final double value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold ? Theme.of(context).textTheme.titleMedium : Theme.of(context).textTheme.bodyMedium;
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

class _CheckoutBar extends ConsumerWidget {
  const _CheckoutBar({required this.cart, required this.onCheckout});

  final PosCartState cart;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(posCartProvider.notifier);
    final total = notifier.total;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Total: ${total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            FilledButton.icon(
              onPressed: cart.items.isEmpty ? null : onCheckout,
              icon: const Icon(Icons.payments),
              label: const Text('Pay (Cash)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CashDialog extends StatefulWidget {
  const _CashDialog();

  @override
  State<_CashDialog> createState() => _CashDialogState();
}

class _CashDialogState extends State<_CashDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double? _parse(String v) {
    final normalized = v.trim().replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cash payment'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          decoration: const InputDecoration(labelText: 'Cash received'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          validator: (v) {
            final parsed = _parse(v ?? '');
            if (parsed == null) return 'Invalid number';
            if (parsed < 0) return 'Must be >= 0';
            return null;
          },
          onFieldSubmitted: (_) {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(_parse(_controller.text));
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(_parse(_controller.text));
          },
          child: const Text('Pay'),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primary : theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? primary : const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: selected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
