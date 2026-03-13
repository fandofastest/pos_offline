import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/category.dart';
import '../providers/catalog_providers.dart';
import '../widgets/pos_app_bar.dart';

class CategoryPage extends ConsumerWidget {
  const CategoryPage({super.key});

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

  Future<void> _openUpsertDialog(BuildContext context, WidgetRef ref, {Category? category}) async {
    final controller = TextEditingController(text: category?.name ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(category == null ? 'New category' : 'Edit category'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              onFieldSubmitted: (_) {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(context).pop(controller.text.trim());
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(context).pop(controller.text.trim());
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    final repo = ref.read(categoryRepositoryProvider);
    await repo.upsert(Category(id: category?.id, name: result));
    ref.invalidate(categoriesProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Category category) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete category'),
          content: Text('Delete "${category.name}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
          ],
        );
      },
    );
    if (ok != true) return;

    final repo = ref.read(categoryRepositoryProvider);
    await repo.delete(category.id!);
    ref.invalidate(categoriesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: PosAppBar(
        title: 'Category Management',
        subtitle: 'Organize your products',
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(categoriesProvider),
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
        child: categories.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(child: Text('No categories'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final c = items[index];
                return _shadowCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.folder_open_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 2),
                              Text('Category', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        _pillIconButton(
                          tooltip: 'Edit',
                          onPressed: () => _openUpsertDialog(context, ref, category: c),
                          icon: Icons.edit_outlined,
                          bg: const Color(0xFFEFF6FF),
                          fg: Theme.of(context).colorScheme.primary,
                        ),
                        _pillIconButton(
                          tooltip: 'Delete',
                          onPressed: () => _delete(context, ref, c),
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
    );
  }
}
