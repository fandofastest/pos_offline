import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../widgets/pos_app_bar.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final taxRate = ref.watch(taxRateProvider);
    final lowStock = ref.watch(lowStockThresholdProvider);

    return Scaffold(
      appBar: const PosAppBar(
        title: 'Settings',
        subtitle: 'Customize your POS',
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _shadowCard(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Icon(Icons.palette_outlined, color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Theme', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text('Choose light or dark mode', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.system, label: Text('System')),
                        ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                        ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                      ],
                      selected: {mode},
                      onSelectionChanged: (value) {
                        ref.read(themeModeProvider.notifier).setThemeMode(value.first);
                      },
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Icon(Icons.point_of_sale_outlined, color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('POS', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text('Tax & inventory alerts', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Tax rate (%)',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        SizedBox(
                          width: 140,
                          child: TextFormField(
                            initialValue: (taxRate * 100).toStringAsFixed(2),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.end,
                            onFieldSubmitted: (value) {
                              final parsed = double.tryParse(value.replaceAll(',', '.'));
                              if (parsed == null) return;
                              ref.read(taxRateProvider.notifier).setRate(parsed / 100);
                            },
                            decoration: const InputDecoration(
                              hintText: '10.00',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Low stock alert',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text('Alert when stock is <= $lowStock', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            lowStock.toString(),
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: lowStock.toDouble(),
                      min: 0,
                      max: 50,
                      divisions: 50,
                      label: lowStock.toString(),
                      onChanged: (v) {
                        ref.read(lowStockThresholdProvider.notifier).setThreshold(v.round());
                      },
                    ),
                    Text(
                      'Tip: press Enter after editing tax rate to save.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
