import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/transaction_provider.dart';
import '../services/category_provider.dart';

class TransactionForm extends StatefulWidget {
  final Transaction? existingTransaction;
  final bool shrinkWrap; // if true, will not pop the parent route on save
  final VoidCallback? onSaved;

  const TransactionForm({
    super.key,
    this.existingTransaction,
    this.shrinkWrap = false,
    this.onSaved,
  });

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();

  late TransactionType _selectedType;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  // Categories are provided by CategoryProvider (persisted with Hive)

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTransaction;
    if (existing != null) {
      _selectedType = existing.type;
      _amountController.text = existing.amount.toString();
      _descriptionController.text = existing.description;
      _selectedCategory = existing.category;
      _selectedDate = existing.date;
    } else {
      _selectedType = TransactionType.expense;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submitData() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
        );
        return;
      }

      final enteredAmount = double.parse(_amountController.text);
      final existing = widget.existingTransaction;
      final newTransaction = Transaction(
        id: existing?.id,
        type: _selectedType,
        amount: enteredAmount,
        category: _selectedCategory!,
        description: _descriptionController.text,
        date: _selectedDate,
      );

      _submitHelper(newTransaction, isUpdate: existing != null);
    }
  }

  Future<void> _submitHelper(
    Transaction newTransaction, {
    bool isUpdate = false,
  }) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      final provider = Provider.of<TransactionProvider>(context, listen: false);
      if (isUpdate) {
        await provider.updateTransaction(newTransaction);
      } else {
        await provider.addTransaction(newTransaction);
      }

      if (mounted) {
        // Dismiss loading dialog
        Navigator.of(context, rootNavigator: true).pop();

        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUpdate
                  ? 'Transaksi berhasil diupdate'
                  : 'Transaksi berhasil disimpan',
            ),
          ),
        );

        // Call optional onSaved callback (parent can switch tabs)
        if (widget.onSaved != null) {
          widget.onSaved!();
        }

        // Close the current route only when not shrinkWrapped and no onSaved callback was provided
        if (!widget.shrinkWrap && widget.onSaved == null) {
          Navigator.of(context).pop();
        }
      }
    } catch (error) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catProvider = Provider.of<CategoryProvider>(context);
    final providerCategories = catProvider.categories;

    // Fallback defaults if provider has no categories
    final defaultExpense = [
      'Makan',
      'Transport',
      'Belanja',
      'Tagihan',
      'Hiburan',
      'Kesehatan',
      'Lainnya',
    ];
    final defaultIncome = ['Gaji', 'Bonus', 'Hadiah', 'Investasi', 'Lainnya'];

    final categories = providerCategories.isNotEmpty
        ? providerCategories
        : (_selectedType == TransactionType.expense
              ? defaultExpense
              : defaultIncome);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Type Selector
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text("Pengeluaran"),
                  icon: Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text("Pemasukan"),
                  icon: Icon(Icons.arrow_downward),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<TransactionType> newSelection) {
                setState(() {
                  _selectedType = newSelection.first;
                  _selectedCategory = null; // Reset category on type change
                });
              },
            ),
            const SizedBox(height: 24),

            // Amount Input
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Nominal",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixText: "Rp ",
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Masukkan nominal';
                }
                if (double.tryParse(value) == null) {
                  return 'Masukkan angka yang valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: "Kategori",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Description Input
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: "Deskripsi (Opsional)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date Picker
            InkWell(
              onTap: _presentDatePicker,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: "Tanggal",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            FilledButton(
              onPressed: _submitData,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.existingTransaction != null
                    ? "Update Transaksi"
                    : "Simpan Transaksi",
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
