import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/savings_target_model.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';
import '../services/transaction_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/design_tokens.dart';

class TargetsScreen extends StatefulWidget {
  const TargetsScreen({super.key});

  @override
  State<TargetsScreen> createState() => _TargetsScreenState();
}

class _TargetsScreenState extends State<TargetsScreen> {
  late Box<SavingsTarget> _targetsBox;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = true;
  bool _showAddForm = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    _targetsBox = await Hive.openBox<SavingsTarget>('savings_targets');

    // Get current user ID
    final apiService = ApiService();
    _currentUserId = await apiService.getUserId();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  double _getCurrentBalance() {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final totalIncome = provider.transactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final totalExpense = provider.transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    return totalIncome - totalExpense;
  }

  Future<void> _addTarget() async {
    if (_formKey.currentState!.validate()) {
      final currentBalance = _getCurrentBalance();

      final target = SavingsTarget(
        name: _nameController.text.trim(),
        targetAmount: CurrencyFormatter.parseCurrency(
          _targetAmountController.text,
        ),
        currentProgress: currentBalance, // Auto-set from current balance
        deadline: _selectedDeadline,
        userId: _currentUserId,
      );

      await _targetsBox.put(target.id, target);
      _clearForm();
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Target "${target.name}" berhasil ditambahkan'),
          ),
        );
      }
    }
  }

  Future<void> _deleteTarget(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Target'),
        content: const Text('Apakah Anda yakin ingin menghapus target ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _targetsBox.delete(id);
      setState(() {});
    }
  }

  void _clearForm() {
    _nameController.clear();
    _targetAmountController.clear();
    _selectedDeadline = DateTime.now().add(const Duration(days: 30));
    _showAddForm = false;
  }

  Future<void> _selectDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  String _getDeadlineText(DateTime deadline) {
    final now = DateTime.now();
    final diff = deadline.difference(now).inDays;

    if (diff < 0) return 'Terlambat';
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Besok';
    if (diff < 7) return '$diff hari lagi';
    if (diff < 30) return '${(diff / 7).round()} minggu lagi';
    return DateFormat('dd MMM yyyy').format(deadline);
  }

  @override
  Widget build(BuildContext context) {
    final currentBalance = _getCurrentBalance();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Targets'),
        actions: [
          IconButton(
            icon: Icon(_showAddForm ? Icons.close : Icons.add),
            onPressed: () {
              setState(() {
                _showAddForm = !_showAddForm;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Balance Card with App Theme
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: DesignTokens.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: DesignTokens.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saldo Saat Ini',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(currentBalance),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showAddForm) _buildAddForm(),
                Expanded(child: _buildTargetsList(currentBalance)),
              ],
            ),
      floatingActionButton: _showAddForm
          ? null
          : FloatingActionButton(
              onPressed: () {
                setState(() {
                  _showAddForm = true;
                });
              },
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildAddForm() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.add_circle,
                  color: DesignTokens.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Tambah Target Baru',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: DesignTokens.neutralHigh,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: DesignTokens.neutralHigh),
              decoration: InputDecoration(
                labelText: 'Nama Target',
                labelStyle: TextStyle(color: DesignTokens.neutralLow),
                filled: true,
                fillColor: DesignTokens.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.flag_outlined,
                  color: DesignTokens.primary,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama target wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _targetAmountController,
              style: const TextStyle(color: DesignTokens.neutralHigh),
              decoration: InputDecoration(
                labelText: 'Jumlah Target',
                labelStyle: TextStyle(color: DesignTokens.neutralLow),
                filled: true,
                fillColor: DesignTokens.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.attach_money,
                  color: DesignTokens.success,
                ),
              ),
              inputFormatters: [CurrencyTextInputFormatter()],
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Jumlah target wajib diisi';
                }
                final amount = CurrencyFormatter.parseCurrency(value);
                if (amount <= 0) {
                  return 'Jumlah target harus lebih dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDeadline,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DesignTokens.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: DesignTokens.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Deadline',
                            style: TextStyle(
                              fontSize: 12,
                              color: DesignTokens.neutralLow,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM yyyy').format(_selectedDeadline),
                            style: const TextStyle(
                              fontSize: 16,
                              color: DesignTokens.neutralHigh,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedDeadline.isBefore(DateTime.now())
                            ? DesignTokens.danger.withOpacity(0.2)
                            : DesignTokens.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getDeadlineText(_selectedDeadline),
                        style: TextStyle(
                          color: _selectedDeadline.isBefore(DateTime.now())
                              ? DesignTokens.danger
                              : DesignTokens.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addTarget,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Simpan Target',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetsList(double currentBalance) {
    // Filter targets by current user ID
    final targets =
        _targetsBox.values
            .where((target) => target.userId == _currentUserId)
            .toList()
          ..sort((a, b) => a.deadline.compareTo(b.deadline));

    if (targets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: DesignTokens.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _showAddForm ? Icons.edit : Icons.flag,
                size: 64,
                color: DesignTokens.neutralLow,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _showAddForm
                  ? 'Isi form di bawah untuk menambah target'
                  : 'Belum ada target',
              style: TextStyle(fontSize: 16, color: DesignTokens.neutralLow),
            ),
            if (!_showAddForm)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showAddForm = true;
                    });
                  },
                  icon: const Icon(Icons.add, color: DesignTokens.primary),
                  label: const Text(
                    'Tambah Target',
                    style: TextStyle(color: DesignTokens.primary),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: targets.length,
      itemBuilder: (context, index) {
        final target = targets[index];
        // Update progress based on current balance
        if (target.currentProgress != currentBalance) {
          final updated = target.copyWith(currentProgress: currentBalance);
          _targetsBox.put(target.id, updated);
        }
        return _buildTargetCard(target);
      },
    );
  }

  Widget _buildTargetCard(SavingsTarget target) {
    final progress = target.progressPercentage;
    final isOverdue = target.isOverdue;

    Color statusColor;
    if (target.isCompleted) {
      statusColor = DesignTokens.success;
    } else if (isOverdue) {
      statusColor = DesignTokens.danger;
    } else {
      statusColor = DesignTokens.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  target.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: DesignTokens.neutralHigh,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  target.isCompleted
                      ? 'Selesai'
                      : (isOverdue
                            ? 'Terlambat'
                            : '${progress.toStringAsFixed(0)}%'),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyFormatter.format(target.currentProgress),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.neutralHigh,
                ),
              ),
              Text(
                'dari ${CurrencyFormatter.format(target.targetAmount)}',
                style: TextStyle(fontSize: 14, color: DesignTokens.neutralLow),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 8,
                width:
                    MediaQuery.of(context).size.width *
                    0.7 *
                    (progress / 100).clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor, statusColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMM yyyy').format(target.deadline),
                style: TextStyle(
                  fontSize: 13,
                  color: isOverdue
                      ? DesignTokens.danger
                      : DesignTokens.neutralLow,
                ),
              ),
              if (!target.isCompleted && target.remainingAmount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Sisa: ${CurrencyFormatter.format(target.remainingAmount)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: DesignTokens.success,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
