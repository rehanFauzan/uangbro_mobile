import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showAddForm = false;
  bool _isEditing = false;
  String? _editingTargetId;
  List<dynamic> _targets = [];

  @override
  void initState() {
    super.initState();
    _loadTargets();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadTargets() async {
    try {
      // Check if user is logged in first
      final userId = await _apiService.getUserId();
      if (userId == null) {
        // User not logged in yet, just show empty list
        if (mounted) {
          setState(() {
            _targets = [];
            _isLoading = false;
          });
        }
        return;
      }

      final targets = await _apiService.getTargets();
      if (mounted) {
        setState(() {
          _targets = targets;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Only show error if it's not a login-related issue
      final errorStr = e.toString();
      if (errorStr.contains('User not logged in') ||
          errorStr.contains('not logged in')) {
        // User not logged in, this is expected - just show empty list
        if (mounted) {
          setState(() {
            _targets = [];
            _isLoading = false;
          });
        }
      } else {
        // Real error - show message
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
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

  Future<void> _saveTarget() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final name = _nameController.text.trim();
        final targetAmount = CurrencyFormatter.parseCurrency(
          _targetAmountController.text,
        );
        final deadline = DateFormat('yyyy-MM-dd').format(_selectedDeadline);

        if (_isEditing && _editingTargetId != null) {
          // Update existing target
          await _apiService.updateTarget(
            targetId: _editingTargetId!,
            name: name,
            targetAmount: targetAmount,
            deadline: deadline,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Target berhasil diperbarui')),
            );
          }
        } else {
          // Add new target
          await _apiService.addTarget(
            name: name,
            targetAmount: targetAmount,
            deadline: deadline,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Target "$name" berhasil ditambahkan')),
            );
          }
        }

        _clearForm();
        await _loadTargets();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menyimpan target: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  void _editTarget(dynamic target) {
    setState(() {
      _isEditing = true;
      _editingTargetId = target['id'].toString();
      _nameController.text = target['name'];
      _targetAmountController.text = target['target_amount'].toString();
      _selectedDeadline = DateTime.parse(target['deadline']);
      _showAddForm = true;
    });
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
            child: const Text(
              'Hapus',
              style: TextStyle(color: DesignTokens.danger),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _apiService.deleteTarget(id);
        await _loadTargets();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Target berhasil dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menghapus target: $e')));
        }
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _targetAmountController.clear();
    _selectedDeadline = DateTime.now().add(const Duration(days: 30));
    _showAddForm = false;
    _isEditing = false;
    _editingTargetId = null;
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

  double _getProgressPercentage(dynamic target) {
    final currentProgress =
        double.tryParse(target['current_progress'].toString()) ?? 0;
    final targetAmount =
        double.tryParse(target['target_amount'].toString()) ?? 1;
    if (targetAmount <= 0) return 0;
    return ((currentProgress / targetAmount) * 100).clamp(0, 100);
  }

  bool _isOverdue(dynamic target) {
    if (target['is_completed'] == 1) return false;
    final deadline = DateTime.parse(target['deadline']);
    return DateTime.now().isAfter(deadline);
  }

  @override
  Widget build(BuildContext context) {
    final currentBalance = _getCurrentBalance();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Targets'),
        actions: [
          if (_showAddForm)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _showAddForm = false;
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
                Icon(
                  _isEditing ? Icons.edit : Icons.add_circle,
                  color: DesignTokens.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  _isEditing ? 'Edit Target' : 'Tambah Target Baru',
                  style: const TextStyle(
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
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              ],
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
                onPressed: _isSaving ? null : _saveTarget,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Perbarui Target' : 'Simpan Target',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetsList(double currentBalance) {
    if (_targets.isEmpty) {
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
      itemCount: _targets.length,
      itemBuilder: (context, index) {
        final target = _targets[index];
        final targetAmount =
            double.tryParse(target['target_amount'].toString()) ?? 1;

        // Use current balance as progress
        final currentProgress = currentBalance;
        final progress = targetAmount > 0
            ? ((currentProgress / targetAmount) * 100).clamp(0, 100)
            : 0;
        final remainingAmount = targetAmount - currentProgress;
        final isOverdue = _isOverdue(target);

        Color statusColor;
        if (target['is_completed'] == 1) {
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
                      target['name'],
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
                      target['is_completed'] == 1
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
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _editTarget(target),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: DesignTokens.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: DesignTokens.primary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _deleteTarget(target['id'].toString()),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: DesignTokens.danger.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: DesignTokens.danger,
                        size: 18,
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
                    CurrencyFormatter.format(currentProgress),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.neutralHigh,
                    ),
                  ),
                  Text(
                    'dari ${CurrencyFormatter.format(targetAmount)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: DesignTokens.neutralLow,
                    ),
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
                    DateFormat(
                      'dd MMM yyyy',
                    ).format(DateTime.parse(target['deadline'])),
                    style: TextStyle(
                      fontSize: 13,
                      color: isOverdue
                          ? DesignTokens.danger
                          : DesignTokens.neutralLow,
                    ),
                  ),
                  if (target['is_completed'] != 1 && remainingAmount > 0)
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
                        'Sisa: ${CurrencyFormatter.format(remainingAmount)}',
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
      },
    );
  }
}
