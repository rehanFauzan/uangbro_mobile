import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/savings_target_model.dart';
import '../utils/currency_formatter.dart';

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
  final _progressController = TextEditingController();
  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = true;
  bool _showAddForm = false;

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    _targetsBox = await Hive.openBox<SavingsTarget>('savings_targets');
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _addTarget() async {
    if (_formKey.currentState!.validate()) {
      final target = SavingsTarget(
        name: _nameController.text.trim(),
        targetAmount: CurrencyFormatter.parseCurrency(
          _targetAmountController.text,
        ),
        currentProgress: _progressController.text.isEmpty
            ? 0
            : CurrencyFormatter.parseCurrency(_progressController.text),
        deadline: _selectedDeadline,
      );

      await _targetsBox.put(target.id, target);
      _clearForm();
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Target berhasil ditambahkan')),
        );
      }
    }
  }

  Future<void> _updateProgress(String id, double newProgress) async {
    final target = _targetsBox.get(id);
    if (target != null) {
      final updated = target.copyWith(
        currentProgress: newProgress,
        isCompleted: newProgress >= target.targetAmount,
      );
      await _targetsBox.put(id, updated);
      setState(() {});
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
    _progressController.clear();
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

  String _getDeadlineText() {
    final now = DateTime.now();
    final deadline = _selectedDeadline;
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
                if (_showAddForm) _buildAddForm(),
                Expanded(child: _buildTargetsList()),
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
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tambah Target Baru',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Target',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama target wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetAmountController,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Target',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _progressController,
                decoration: const InputDecoration(
                  labelText: 'Progress Saat Ini (opsional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.trending_up),
                ),
                inputFormatters: [CurrencyTextInputFormatter()],
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _selectDeadline,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Deadline: ${DateFormat('dd MMM yyyy').format(_selectedDeadline)}',
                      ),
                      Text(
                        '($_getDeadlineText())',
                        style: TextStyle(
                          color: _selectedDeadline.isBefore(DateTime.now())
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addTarget,
                  child: const Text('Simpan Target'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetsList() {
    final targets = _targetsBox.values.toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));

    if (targets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showAddForm ? Icons.edit : Icons.flag,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _showAddForm
                  ? 'Isi form di bawah untuk menambah target'
                  : 'Belum ada target',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (!_showAddForm)
              TextButton(
                onPressed: () {
                  setState(() {
                    _showAddForm = true;
                  });
                },
                child: const Text('Tambah Target'),
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
        return _buildTargetCard(target);
      },
    );
  }

  Widget _buildTargetCard(SavingsTarget target) {
    final progress = target.progressPercentage;
    final remaining = target.remainingAmount;
    final isOverdue = target.isOverdue;
    final daysRemaining = target.daysRemaining;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    ),
                  ),
                ),
                if (target.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Selesai',
                      style: TextStyle(color: Colors.green[700], fontSize: 12),
                    ),
                  )
                else if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Terlambat',
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                    ),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteTarget(target.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CurrencyFormatter.format(target.currentProgress),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  'dari ${CurrencyFormatter.format(target.targetAmount)}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  height: 8,
                  width:
                      MediaQuery.of(context).size.width *
                      0.9 *
                      (progress / 100),
                  decoration: BoxDecoration(
                    color: target.isCompleted
                        ? Colors.green
                        : (isOverdue ? Colors.red : Colors.blue),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progress.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!target.isCompleted)
                  Text(
                    isOverdue
                        ? 'Terlambat ${-daysRemaining} hari'
                        : '$_getDeadlineText()',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverdue ? Colors.red : Colors.grey[600],
                    ),
                  ),
              ],
            ),
            if (!target.isCompleted && remaining > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.savings_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Sisa: ${CurrencyFormatter.format(remaining)}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ],
            if (!target.isCompleted)
              TextButton(
                onPressed: () => _showProgressDialog(target),
                child: const Text('Update Progress'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showProgressDialog(SavingsTarget target) async {
    final controller = TextEditingController(
      text: target.currentProgress > 0
          ? CurrencyFormatter.format(target.currentProgress)
          : '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Progress'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Target: ${target.name}'),
            const SizedBox(height: 8),
            Text(
              'Target Amount: ${CurrencyFormatter.format(target.targetAmount)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Progress Baru',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.trending_up),
              ),
              inputFormatters: [CurrencyTextInputFormatter()],
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newProgress = CurrencyFormatter.parseCurrency(
                controller.text,
              );
              _updateProgress(target.id, newProgress);
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
