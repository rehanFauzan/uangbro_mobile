import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/design_tokens.dart';
import '../models/transaction_model.dart';
import '../services/transaction_provider.dart';
import '../services/category_provider.dart';

class TransactionForm extends StatefulWidget {
  final Transaction? existingTransaction;
  final bool shrinkWrap; // if true, will not pop the parent route on save
  final VoidCallback? onSaved;
  final TransactionType? initialType;

  const TransactionForm({
    super.key,
    this.existingTransaction,
    this.shrinkWrap = false,
    this.onSaved,
    this.initialType,
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
      _selectedCategory = existing.category.trim();
      _selectedDate = existing.date;
    } else if (widget.initialType != null) {
      _selectedType = widget.initialType!;
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

        // Close the current route when appropriate:
        // - if not shrinkWrapped and no onSaved callback provided, close normally
        // - if shrinkWrapped (used inside bottom sheet), also close the sheet here
        if (!widget.shrinkWrap && widget.onSaved == null) {
          Navigator.of(context).pop();
        } else if (widget.shrinkWrap) {
          // Close the bottom sheet / dialog that contains this form
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
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

    final categoriesRaw = providerCategories.isNotEmpty
        ? providerCategories
        : (_selectedType == TransactionType.expense
              ? defaultExpense
              : defaultIncome);
    // Order-preserving dedupe: keep first occurrence and drop later duplicates.
    final seen = <String>{};
    final categories = <String>[];
    for (final c in categoriesRaw) {
      final normalized = c.trim();
      if (normalized.isEmpty) continue;
      if (seen.add(normalized)) categories.add(normalized);
    }
    // Normalize selected category and ensure it's present
    final selectedNormalized = _selectedCategory?.trim();
    if (selectedNormalized != null &&
        selectedNormalized.isNotEmpty &&
        !categories.contains(selectedNormalized)) {
      categories.insert(0, selectedNormalized);
      _selectedCategory = selectedNormalized; // keep state normalized
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: DesignTokens.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Type Selector
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: DesignTokens.bg.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SegmentedButton<TransactionType>(
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
              ),
              const SizedBox(height: 18),

              // Amount Input
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 12, right: 8),
                    child: Icon(Icons.attach_money),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 48),
                  labelText: "Nominal",
                  filled: true,
                  fillColor: DesignTokens.bg.withOpacity(0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintText: "0",
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
              const SizedBox(height: 14),

              // Category Dropdown
              DropdownButtonFormField<String>(
                // use initialValue to avoid deprecated 'value' usage and ensure
                // the dropdown has the matching selected item
                initialValue: _selectedCategory?.trim(),
                decoration: InputDecoration(
                  labelText: "Kategori",
                  filled: true,
                  fillColor: DesignTokens.bg.withOpacity(0.02),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value?.trim();
                  });
                },
              ),
              const SizedBox(height: 14),

              // Description Input
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.note),
                  labelText: "Deskripsi (Opsional)",
                  filled: true,
                  fillColor: DesignTokens.bg.withOpacity(0.02),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Date Picker
              InkWell(
                onTap: _presentDatePicker,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: "Tanggal",
                    filled: true,
                    fillColor: DesignTokens.bg.withOpacity(0.02),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Save Button (gradient)
              Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: DesignTokens.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _submitData,
                    child: SizedBox(
                      height: 52,
                      child: Center(
                        child: Text(
                          widget.existingTransaction != null
                              ? "Update Transaksi"
                              : "Simpan Transaksi",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
