import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import 'transaction_form.dart';

class AddTransactionScreen extends StatelessWidget {
  final Transaction? existingTransaction;
  final VoidCallback? onSaved;

  const AddTransactionScreen({
    super.key,
    this.existingTransaction,
    this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    final isEdit = existingTransaction != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Transaksi" : "Tambah Transaksi"),
      ),
      body: TransactionForm(
        existingTransaction: existingTransaction,
        onSaved: onSaved,
      ),
    );
  }
}
