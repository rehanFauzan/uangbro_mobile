import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/transaction_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  TransactionType _selectedType = TransactionType.expense;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  final List<String> _expenseCategories = [
    'Makan',
    'Transport',
    'Belanja',
    'Tagihan',
    'Hiburan',
    'Kesehatan',
    'Lainnya',
  ];

  final List<String> _incomeCategories = [
    'Gaji',
    'Bonus',
    'Hadiah',
    'Investasi',
    'Lainnya',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
      final newTransaction = Transaction(
        type: _selectedType,
        amount: enteredAmount,
        category: _selectedCategory!,
        description: _descriptionController.text,
        date: _selectedDate,
      );

      _submitHelper(newTransaction);
    }
  }

  Future<void> _submitHelper(Transaction newTransaction) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      await Provider.of<TransactionProvider>(context, listen: false)
          .addTransaction(newTransaction);

      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil disimpan')),
        );
        
        // Clear form
        _amountController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedCategory = null;
          _selectedDate = DateTime.now();
        });
      }
    } catch (error) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final categories = _selectedType == TransactionType.expense 
        ? _expenseCategories 
        : _incomeCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Transaksi"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                    (states) {
                      if (states.contains(MaterialState.selected)) {
                        return _selectedType == TransactionType.expense
                            ? Colors.red.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2);
                      }
                      return null;
                    },
                  ),
                  foregroundColor: MaterialStateProperty.resolveWith<Color?>(
                    (states) {
                       if (states.contains(MaterialState.selected)) {
                        return _selectedType == TransactionType.expense
                            ? Colors.red
                            : Colors.green;
                      }
                      return null;
                    } 
                  )
                ),
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
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
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
                child: const Text("Simpan Transaksi"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
