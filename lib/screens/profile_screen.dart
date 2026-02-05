import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/transaction_provider.dart';
import '../screens/categories_screen.dart';
import '../screens/analytics_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil")),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          // User Profile Header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Raihan",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  "user@uangbro.app",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Settings Section
          _buildSectionHeader(context, "Pengaturan"),

          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              "Reset Semua Data",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _confirmReset(context),
          ),

          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Kelola Kategori'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Export CSV'),
            onTap: () {
              final provider = Provider.of<TransactionProvider>(
                context,
                listen: false,
              );
              final csv = provider.exportToCsv();
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Export CSV'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(child: SelectableText(csv)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Import CSV (Paste)'),
            onTap: () async {
              final controller = TextEditingController();
              await showDialog(
                context: context,
                builder: (dctx) => AlertDialog(
                  title: const Text('Import CSV'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: TextField(
                      controller: controller,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        hintText: 'Paste CSV content here',
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dctx).pop(),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final csv = controller.text.trim();
                        if (csv.isNotEmpty) {
                          Navigator.of(dctx).pop();
                          final provider = Provider.of<TransactionProvider>(
                            context,
                            listen: false,
                          );
                          final imported = await provider.importFromCsv(csv);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Imported $imported rows'),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Import'),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.pie_chart_outline),
            title: const Text('Analitik'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
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
          "Semua data transaksi akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await Provider.of<TransactionProvider>(
                context,
                listen: false,
              ).resetData();
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
