import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/catalog_providers.dart';
import '../providers/transaction_providers.dart';
import '../widgets/pos_app_bar.dart';
import 'category_page.dart';
import 'pos_page.dart';
import 'product_management_page.dart';
import 'settings_page.dart';
import 'transaction_history_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  Widget _shadowCard({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Card(child: child),
    );
  }

  Widget _statCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color iconBg,
    required Color iconFg,
  }) {
    return _shadowCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
              alignment: Alignment.center,
              child: Icon(icon, color: iconFg),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final txsAsync = ref.watch(transactionsProvider);

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return Scaffold(
      appBar: PosAppBar(
        title: 'Dashboard',
        subtitle: "Good day! Here's your store overview",
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
              ref.invalidate(sessionProvider);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            txsAsync.when(
              data: (txs) {
                final todaySales = txs
                    .where((e) => e.createdAt.isAfter(startOfDay) && e.createdAt.isBefore(endOfDay))
                    .fold<double>(0.0, (sum, e) => sum + e.total);
                final txCount = txs.length;

                final productCount = productsAsync.maybeWhen(data: (items) => items.length, orElse: () => 0);

                return Column(
                  children: [
                    _statCard(
                      context: context,
                      title: 'Today Sales',
                      value: '\$${todaySales.toStringAsFixed(2)}',
                      icon: Icons.attach_money,
                      iconBg: const Color(0xFFE8F7ED),
                      iconFg: const Color(0xFF16A34A),
                    ),
                    const SizedBox(height: 12),
                    _statCard(
                      context: context,
                      title: 'Transactions',
                      value: '$txCount',
                      icon: Icons.trending_up,
                      iconBg: const Color(0xFFEFF6FF),
                      iconFg: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    _statCard(
                      context: context,
                      title: 'Products',
                      value: '$productCount',
                      icon: Icons.inventory_2_outlined,
                      iconBg: const Color(0xFFEFF6FF),
                      iconFg: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                );
              },
              error: (e, st) => _shadowCard(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text('Failed to load dashboard stats: $e'),
                ),
              ),
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
            ),
            const SizedBox(height: 18),
            Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 600;
                return GridView.count(
                  crossAxisCount: wide ? 4 : 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: wide ? 1.35 : 1.25,
                  children: [
                    _ActionTile(
                      title: 'Start Sale',
                      icon: Icons.shopping_cart_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PosPage())),
                    ),
                    _ActionTile(
                      title: 'Products',
                      icon: Icons.inventory_2_outlined,
                      color: const Color(0xFF0EA5E9),
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const ProductManagementPage())),
                    ),
                    _ActionTile(
                      title: 'Transactions',
                      icon: Icons.receipt_long_outlined,
                      color: const Color(0xFFE5E7EB),
                      darkText: true,
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const TransactionHistoryPage())),
                    ),
                    _ActionTile(
                      title: 'Categories',
                      icon: Icons.category_outlined,
                      color: const Color(0xFFE5E7EB),
                      darkText: true,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoryPage())),
                    ),
                    _ActionTile(
                      title: 'Settings',
                      icon: Icons.settings_outlined,
                      color: const Color(0xFFE5E7EB),
                      darkText: true,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.color,
    this.darkText = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final bool darkText;

  @override
  Widget build(BuildContext context) {
    final fg = darkText ? Colors.black : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 28),
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
