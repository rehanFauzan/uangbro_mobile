import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/transaction_provider.dart';
import 'transaction_form.dart';
import '../utils/currency_formatter.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _sortOption =
      'date_desc'; // date_desc, date_asc, amount_desc, amount_asc

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Transaksi"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              setState(() {
                _sortOption = v;
              });
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'date_desc', child: Text('Terbaru')),
              const PopupMenuItem(value: 'date_asc', child: Text('Terlama')),
              const PopupMenuItem(
                value: 'amount_desc',
                child: Text('Jumlah (besar → kecil)'),
              ),
              const PopupMenuItem(
                value: 'amount_asc',
                child: Text('Jumlah (kecil → besar)'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Cari kategori, deskripsi, atau nominal...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (v) => setState(() {}),
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Consumer<TransactionProvider>(
              builder: (context, provider, _) {
                return Row(
                  children: [
                    _buildFilterChip(
                      context,
                      provider,
                      label: "Semua",
                      type: null,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      context,
                      provider,
                      label: "Pemasukan",
                      type: TransactionType.income,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      context,
                      provider,
                      label: "Pengeluaran",
                      type: TransactionType.expense,
                    ),
                  ],
                );
              },
            ),
          ),

          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, provider, child) {
                final transactions = provider.transactions;

                // Apply search filter
                final query = _searchController.text.toLowerCase().trim();
                List<Transaction> displayed = transactions.where((tx) {
                  if (query.isEmpty) return true;
                  final amountStr = tx.amount.toString();
                  final dateStr = DateFormat(
                    'dd MMM yyyy',
                  ).format(tx.date).toLowerCase();
                  return tx.category.toLowerCase().contains(query) ||
                      tx.description.toLowerCase().contains(query) ||
                      amountStr.contains(query) ||
                      dateStr.contains(query);
                }).toList();

                // Sort according to option
                switch (_sortOption) {
                  case 'date_asc':
                    displayed.sort((a, b) => a.date.compareTo(b.date));
                    break;
                  case 'amount_desc':
                    displayed.sort((a, b) => b.amount.compareTo(a.amount));
                    break;
                  case 'amount_asc':
                    displayed.sort((a, b) => a.amount.compareTo(b.amount));
                    break;
                  case 'date_desc':
                  default:
                    displayed.sort((a, b) => b.date.compareTo(a.date));
                }

                if (displayed.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          "Tidak ada riwayat transaksi",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayed.length,
                  itemBuilder: (context, index) {
                    final tx = displayed[index];
                    return _buildTransactionItem(context, provider, tx);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    TransactionProvider provider, {
    required String label,
    required TransactionType? type,
  }) {
    final isSelected = provider.typeFilter == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        provider.setTypeFilter(type);
      },
      showCheckmark: false,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    TransactionProvider provider,
    Transaction tx,
  ) {
    final isExpense = tx.type == TransactionType.expense;

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Hapus Transaksi?"),
            content: const Text("Transaksi ini akan dihapus permanen."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text("Batal"),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text("Hapus", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        // Keep a copy to allow undo
        final deletedTx = tx;
        await provider.deleteTransaction(tx);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Transaksi dihapus'),
              action: SnackBarAction(
                label: 'UNDO',
                onPressed: () async {
                  // Recreate the transaction on backend and refresh
                  await provider.addTransaction(deletedTx);
                },
              ),
              duration: const Duration(seconds: 6),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isExpense
                ? Colors.red.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
            child: Icon(
              isExpense ? Icons.arrow_upward : Icons.arrow_downward,
              color: isExpense ? Colors.red : Colors.green,
              size: 20,
            ),
          ),
          title: Text(tx.category),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tx.description.isNotEmpty) Text(tx.description),
              Text(
                DateFormat('dd MMM yyyy, HH:mm').format(tx.date),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                CurrencyFormatter.format(tx.amount),
                style: TextStyle(
                  color: isExpense ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    // Open the form in a modal bottom sheet for quicker edits
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (ctx) => Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(ctx).viewInsets.bottom,
                        ),
                        child: TransactionForm(
                          existingTransaction: tx,
                          shrinkWrap: true,
                          onSaved: () async {
                            // Close the bottom sheet and refresh transactions
                            if (Navigator.of(ctx).canPop())
                              Navigator.of(ctx).pop();
                            await provider.fetchTransactions();
                          },
                        ),
                      ),
                    );
                  } else if (value == 'delete') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Hapus Transaksi?"),
                        content: const Text(
                          "Transaksi ini akan dihapus permanen.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text("Batal"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text(
                              "Hapus",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      final deletedTx = tx;
                      await provider.deleteTransaction(tx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Transaksi dihapus'),
                            action: SnackBarAction(
                              label: 'UNDO',
                              onPressed: () async {
                                await provider.addTransaction(deletedTx);
                              },
                            ),
                            duration: const Duration(seconds: 6),
                          ),
                        );
                      }
                    }
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
