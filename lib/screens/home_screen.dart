import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/transaction_provider.dart';
import '../utils/currency_formatter.dart';
import '../models/transaction_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Balance Card
              _buildBalanceCard(context, provider),
              const SizedBox(height: 16),
              
              // Income & Expense Row
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      "Pemasukan",
                      provider.totalIncome,
                      Colors.green,
                      Icons.arrow_downward,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      "Pengeluaran",
                      provider.totalExpense,
                      Colors.red,
                      Icons.arrow_upward,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Recent Transactions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Transaksi Terakhir",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Optional: "See All" button could go here
                ],
              ),
              const SizedBox(height: 8),
              
              // Recent Transactions List
              ..._buildRecentTransactions(context, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, TransactionProvider provider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Total Saldo",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(provider.totalBalance),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(amount),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRecentTransactions(
    BuildContext context,
    TransactionProvider provider,
  ) {
    final recent = provider.getRecentTransactions(5);
    
    if (recent.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text("Belum ada transaksi"),
          ),
        )
      ];
    }

    return recent.map((tx) {
      final isExpense = tx.type == TransactionType.expense;
      return Card(
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
          title: Text(tx.category), // Or description?
          subtitle: Text(
            tx.description.isNotEmpty ? tx.description : DateFormat('dd MMM yyyy').format(tx.date),
             style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: Text(
            CurrencyFormatter.format(tx.amount),
            style: TextStyle(
              color: isExpense ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }).toList();
  }
}
