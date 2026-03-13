import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/providers/app_providers.dart';
import 'presentation/screens/dashboard_page.dart';
import 'presentation/screens/login_page.dart';
import 'presentation/theme/app_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final session = ref.watch(sessionProvider);

    return MaterialApp(
      title: 'Offline POS',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: session.when(
        data: (value) => value == null ? const LoginPage() : const DashboardPage(),
        error: (e, st) => Scaffold(
          body: Center(child: Text('Error: $e')),
        ),
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
