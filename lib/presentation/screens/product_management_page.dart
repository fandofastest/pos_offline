import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/product.dart';
import '../providers/catalog_providers.dart';
import '../widgets/pos_app_bar.dart';

class ProductManagementPage extends ConsumerWidget {
  const ProductManagementPage({super.key});

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

  Widget _pillIconButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color bg,
    required Color fg,
    String? tooltip,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Icon(icon, color: fg, size: 18),
      ),
    );
  }

  Future<void> _openUpsertDialog(BuildContext context, WidgetRef ref, {Product? product}) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _ProductUpsertDialog(product: product),
    );

    ref.invalidate(productsProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Product product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete product'),
          content: Text('Delete "${product.name}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
          ],
        );
      },
    );
    if (ok != true) return;

    await ref.read(productRepositoryProvider).delete(product.id!);
    ref.invalidate(productsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final query = ref.watch(productQueryProvider);

    return Scaffold(
      appBar: PosAppBar(
        title: 'Product Management',
        subtitle: 'Manage your inventory',
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(productsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openUpsertDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search by name or barcode',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => ref.read(productQueryProvider.notifier).state = v,
                controller: TextEditingController(text: query)
                  ..selection = TextSelection.collapsed(offset: query.length),
              ),
            ),
            Expanded(
              child: products.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(child: Text('No products'));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                    itemBuilder: (context, index) {
                      final p = items[index];
                      return _shadowCard(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  height: 56,
                                  width: 56,
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
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      p.barcode == null || p.barcode!.isEmpty ? 'No barcode' : p.barcode!,
                                      style: Theme.of(context).textTheme.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          '\$${p.price.toStringAsFixed(2)}',
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.w900,
                                              ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Stock: ${p.stock.toStringAsFixed(0)}',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _pillIconButton(
                                tooltip: 'Edit',
                                onPressed: () => _openUpsertDialog(context, ref, product: p),
                                icon: Icons.edit_outlined,
                                bg: const Color(0xFFEFF6FF),
                                fg: Theme.of(context).colorScheme.primary,
                              ),
                              _pillIconButton(
                                tooltip: 'Delete',
                                onPressed: () => _delete(context, ref, p),
                                icon: Icons.delete_outline,
                                bg: const Color(0xFFFEE2E2),
                                fg: const Color(0xFFDC2626),
                              ),
                            ],
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

class _ProductUpsertDialog extends ConsumerStatefulWidget {
  const _ProductUpsertDialog({this.product});

  final Product? product;

  @override
  ConsumerState<_ProductUpsertDialog> createState() => _ProductUpsertDialogState();
}

class _ProductUpsertDialogState extends ConsumerState<_ProductUpsertDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _barcode;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _unit;

  int? _categoryId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _barcode = TextEditingController(text: p?.barcode ?? '');
    _price = TextEditingController(text: p == null ? '' : p.price.toString());
    _stock = TextEditingController(text: p == null ? '' : p.stock.toString());
    _unit = TextEditingController(text: p?.unit ?? 'pcs');
    _categoryId = p?.categoryId;
  }

  @override
  void dispose() {
    _name.dispose();
    _barcode.dispose();
    _price.dispose();
    _stock.dispose();
    _unit.dispose();
    super.dispose();
  }

  double? _parseDouble(String v) {
    final normalized = v.trim().replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final price = _parseDouble(_price.text) ?? 0;
      final stock = _parseDouble(_stock.text) ?? 0;
      final product = Product(
        id: widget.product?.id,
        name: _name.text.trim(),
        barcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
        categoryId: _categoryId,
        price: price,
        stock: stock,
        unit: _unit.text.trim().isEmpty ? 'pcs' : _unit.text.trim(),
      );
      await ref.read(productRepositoryProvider).upsert(product);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return AlertDialog(
      title: Text(widget.product == null ? 'New product' : 'Edit product'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _barcode,
                  decoration: const InputDecoration(labelText: 'Barcode (optional)'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                categoriesAsync.when(
                  data: (cats) {
                    return DropdownButtonFormField<int?>(
                      value: _categoryId,
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('- No category -')),
                        ...cats.map(
                          (c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _categoryId = v),
                      decoration: const InputDecoration(labelText: 'Category'),
                    );
                  },
                  error: (e, st) => Text('Failed to load categories: $e'),
                  loading: () => const LinearProgressIndicator(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _price,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          final parsed = _parseDouble(v ?? '');
                          if (parsed == null) return 'Invalid number';
                          if (parsed < 0) return 'Must be >= 0';
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stock,
                        decoration: const InputDecoration(labelText: 'Stock'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          final parsed = _parseDouble(v ?? '');
                          if (parsed == null) return 'Invalid number';
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _unit,
                  decoration: const InputDecoration(labelText: 'Unit (pcs, box, etc.)'),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
