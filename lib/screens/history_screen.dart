import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/transaction_provider.dart';
import '../utils/currency_formatter.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Transaksi"),
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Consumer<TransactionProvider>(
              builder: (context, provider, _) {
                return Row(
                  children: [
                    _buildFilterChip(
                      context, 
                      provider, 
                      label: "Semua", 
                      type: null
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      context, 
                      provider, 
                      label: "Pemasukan", 
                      type: TransactionType.income
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      context, 
                      provider, 
                      label: "Pengeluaran", 
                      type: TransactionType.expense
                    ),
                  ],
                );
              }
            ),
          ),
          
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, provider, child) {
                final transactions = provider.transactions;
                
                if (transactions.isEmpty) {
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
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
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
    TransactionProvider provider, 
    {required String label, required TransactionType? type}
  ) {
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
    Transaction tx
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
      onDismissed: (direction) {
        provider.deleteTransaction(tx);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi dihapus')),
        );
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
          trailing: Text(
            CurrencyFormatter.format(tx.amount),
            style: TextStyle(
              color: isExpense ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
