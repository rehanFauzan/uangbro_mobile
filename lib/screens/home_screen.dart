import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/transaction_provider.dart';
import '../utils/currency_formatter.dart';
import '../models/transaction_model.dart';
import '../utils/design_tokens.dart';
import 'add_transaction_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("UangBro")),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Balance Card
              _buildBalanceCard(context, provider),
              const SizedBox(height: 16),

              // Monthly Income & Expense Row (Bulan ini)
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      "Pemasukan (Bulan ini)",
                      provider.monthlyIncome(),
                      Colors.green,
                      Icons.arrow_downward,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      "Pengeluaran (Bulan ini)",
                      provider.monthlyExpense(),
                      Colors.red,
                      Icons.arrow_upward,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Today's small summaries (compact, not full cards)
              Row(
                children: [
                  Expanded(
                    child: _buildSmallSummaryCard(
                      context,
                      "Pemasukan (Hari ini)",
                      provider.dailyIncome(),
                      Colors.green,
                      Icons.arrow_downward,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSmallSummaryCard(
                      context,
                      "Pengeluaran (Hari ini)",
                      provider.dailyExpense(),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: DesignTokens.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DesignTokens.neutralLow.withOpacity(0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 8,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total Saldo",
                style: TextStyle(
                  color: DesignTokens.neutralHigh.withOpacity(0.95),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                CurrencyFormatter.format(provider.totalBalance),
                style: TextStyle(
                  color: DesignTokens.neutralHigh,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Quick actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddTransactionScreen(
                              onSaved: () {
                                // When saved, pop and show confirmation
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Transaksi berhasil disimpan',
                                    ),
                                  ),
                                );
                              },
                              initialType: TransactionType.income,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_downward),
                      label: const Text('Tambah Pemasukan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddTransactionScreen(
                              onSaved: () {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Transaksi berhasil disimpan',
                                    ),
                                  ),
                                );
                              },
                              existingTransaction: null,
                              initialType: TransactionType.expense,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_upward),
                      label: const Text('Tambah Pengeluaran'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DesignTokens.neutralHigh,
                        side: BorderSide(
                          color: DesignTokens.neutralLow.withOpacity(0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
      elevation: 0,
      color: DesignTokens.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DesignTokens.neutralLow,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
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

  Widget _buildSmallSummaryCard(
    BuildContext context,
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: DesignTokens.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DesignTokens.neutralLow,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(amount),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          child: Center(child: Text("Belum ada transaksi")),
        ),
      ];
    }

    return recent.map((tx) {
      final isExpense = tx.type == TransactionType.expense;
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        color: DesignTokens.surface,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isExpense
                ? DesignTokens.danger.withOpacity(0.08)
                : DesignTokens.success.withOpacity(0.08),
            child: Icon(
              isExpense ? Icons.arrow_upward : Icons.arrow_downward,
              color: isExpense ? DesignTokens.danger : DesignTokens.success,
              size: 20,
            ),
          ),
          title: Text(tx.category), // Or description?
          subtitle: Text(
            tx.description.isNotEmpty
                ? tx.description
                : DateFormat('dd MMM yyyy').format(tx.date),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: Text(
            CurrencyFormatter.format(tx.amount),
            style: TextStyle(
              color: isExpense ? DesignTokens.danger : DesignTokens.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }).toList();
  }
}
