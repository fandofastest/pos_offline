import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../providers/app_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  Widget _shadowCard({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Card(child: child),
    );
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.login(username: _username.text.trim(), password: _password.text);
      ref.invalidate(sessionProvider);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _shadowCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            height: 56,
                            width: 56,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 26),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Welcome Back',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in to your POS account',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _username,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            hintText: 'Enter username',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _loading ? null : _login(),
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loading ? null : _login,
                          child: _loading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Sign In'),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Demo credentials: admin/admin, cashier/cashier',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
