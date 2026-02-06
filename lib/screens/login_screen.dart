// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../utils/design_tokens.dart';
import '../services/api_service.dart';
import 'register_screen.dart';
import 'main_wrapper.dart';
import 'package:provider/provider.dart';
import '../services/transaction_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  final ApiService _api = ApiService();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final token = await _api.login(
      _usernameCtrl.text.trim(),
      _passwordCtrl.text,
    );
    setState(() => _loading = false);

    if (token != null) {
      // Refresh transactions and offer claim
      if (!mounted) return;
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      final dialogContext = context;
      await provider.fetchTransactions();

      // Check for legacy transactions (user_id null)
      final legacy = provider.transactions
          .where((t) => t.userId == null || t.userId!.isEmpty)
          .toList();
      if (legacy.isNotEmpty) {
        final doClaim = await showDialog<bool>(
          context: dialogContext,
          builder: (ctx) => AlertDialog(
            title: const Text('Klaim transaksi lama?'),
            content: Text(
              'Kami menemukan ${legacy.length} transaksi lama. Mau klaim ke akunmu supaya tidak hilang?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Nanti'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Klaim'),
              ),
            ],
          ),
        );

        if (doClaim == true) {
          final ids = legacy.map((t) => t.id).toList();
          final result = await _api.claimTransactions(ids);
          if (result['status'] == 'success') {
            await provider.fetchTransactions();
            messenger.showSnackBar(
              const SnackBar(content: Text('Transaksi berhasil diklaim')),
            );
          } else {
            final msg = result['message'] ?? 'Gagal klaim transaksi';
            messenger.showSnackBar(SnackBar(content: Text(msg)));
          }
        }
      }

      // Navigate to app
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const MainWrapper()),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login gagal')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo and title
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignTokens.primary.withAlpha((0.12 * 255).round()),
                ),
                child: Icon(
                  Icons.savings,
                  size: 48,
                  color: DesignTokens.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Selamat datang di UangBro',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kelola keuanganmu dengan mudah. Masuk untuk melanjutkan.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: DesignTokens.neutralLow),
              ),
              const SizedBox(height: 20),

              // Card with form
              Card(
                color: DesignTokens.surface,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _usernameCtrl,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person_outline),
                            hintText: 'Username',
                            filled: true,
                            fillColor: DesignTokens.surface.withAlpha(
                              (0.04 * 255).round(),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Masukkan username'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordCtrl,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_outline),
                            hintText: 'Password',
                            filled: true,
                            fillColor: DesignTokens.surface.withAlpha(
                              (0.04 * 255).round(),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          obscureText: true,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Masukkan password'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DesignTokens.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Masuk',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Belum punya akun? '),
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              ),
                              child: Text(
                                'Daftar',
                                style: TextStyle(color: DesignTokens.primary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
