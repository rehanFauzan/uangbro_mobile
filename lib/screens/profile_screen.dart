import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/transaction_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          // User Profile Header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Pengguna",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  "user@uangbro.app",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Settings Section
          _buildSectionHeader(context, "Pengaturan"),
          
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Reset Semua Data", style: TextStyle(color: Colors.red)),
            onTap: () => _confirmReset(context),
          ),

          const Divider(),

          // About Section
          _buildSectionHeader(context, "Tentang Aplikasi"),
          
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("Versi Aplikasi"),
            trailing: Text("1.0.0"),
          ),
          const ListTile(
            leading: Icon(Icons.code),
            title: Text("Dibuat dengan Flutter"),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reset Data?"),
        content: const Text(
            "Semua data transaksi akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await Provider.of<TransactionProvider>(context, listen: false)
                  .resetData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Semua data berhasil dihapus')),
                );
              }
            },
            child: const Text("Reset", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
