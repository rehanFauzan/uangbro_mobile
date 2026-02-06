import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import 'api_service.dart';

class TransactionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Transaction> _transactions = [];
  List<Transaction> get transactions => _transactions;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  double get totalBalance {
    return totalIncome - totalExpense;
  }

  double get totalIncome {
    return _transactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalExpense {
    return _transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // Monthly totals (default to current month)
  double monthlyIncome({DateTime? forMonth}) {
    final month = forMonth ?? DateTime.now();
    return _transactions
        .where((tx) => tx.type == TransactionType.income)
        .where(
          (tx) => tx.date.year == month.year && tx.date.month == month.month,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double monthlyExpense({DateTime? forMonth}) {
    final month = forMonth ?? DateTime.now();
    return _transactions
        .where((tx) => tx.type == TransactionType.expense)
        .where(
          (tx) => tx.date.year == month.year && tx.date.month == month.month,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Returns a map of category -> total amount for the given month (defaults to current month)
  Map<String, double> categoryTotalsForMonth({DateTime? forMonth}) {
    final month = forMonth ?? DateTime.now();
    final Map<String, double> totals = {};
    for (var tx in _transactions) {
      if (tx.date.year == month.year && tx.date.month == month.month) {
        totals[tx.category] = (totals[tx.category] ?? 0) + tx.amount;
      }
    }
    return totals;
  }

  // Daily totals (default to today)
  double dailyIncome({DateTime? forDay}) {
    final day = forDay ?? DateTime.now();
    return _transactions
        .where((tx) => tx.type == TransactionType.income)
        .where(
          (tx) =>
              tx.date.year == day.year &&
              tx.date.month == day.month &&
              tx.date.day == day.day,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double dailyExpense({DateTime? forDay}) {
    final day = forDay ?? DateTime.now();
    return _transactions
        .where((tx) => tx.type == TransactionType.expense)
        .where(
          (tx) =>
              tx.date.year == day.year &&
              tx.date.month == day.month &&
              tx.date.day == day.day,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // Filters
  TransactionType? _typeFilter;
  TransactionType? get typeFilter => _typeFilter;

  // Initial Loading
  Future<void> init() async {
    await fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    _isLoading = true;
    notifyListeners();
    try {
      final allTransactions = await _apiService.getTransactions();

      if (_typeFilter != null) {
        _transactions = allTransactions
            .where((tx) => tx.type == _typeFilter)
            .toList();
      } else {
        _transactions = allTransactions;
      }

      // Sort by date descending
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      // use debugPrint instead of print for better logging control
      debugPrint("Error fetching transactions: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _apiService.addTransaction(transaction);
    await fetchTransactions();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _apiService.updateTransaction(transaction);
    await fetchTransactions();
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    await _apiService.deleteTransaction(transaction.id);
    await fetchTransactions();
  }

  Future<void> resetData() async {
    // Ideally call API to delete all, but for safety implementing delete one by one
    // or just assume this feature might be restricted server side.
    // For now, let's delete locally loaded ones to simulate valid UI, or add clear API.
    for (var tx in _transactions) {
      await _apiService.deleteTransaction(tx.id);
    }
    await fetchTransactions();
  }

  /// Export current transactions to CSV string. Columns: id,type,amount,category,description,date
  String exportToCsv() {
    final buffer = StringBuffer();
    buffer.writeln('id,type,amount,category,description,date');
    for (var tx in _transactions) {
      final row = [
        tx.id,
        tx.type == TransactionType.income ? 'income' : 'expense',
        tx.amount.toString(),
        '"${tx.category.replaceAll('"', '""')}"',
        '"${tx.description.replaceAll('"', '""')}"',
        tx.date.toIso8601String(),
      ].join(',');
      buffer.writeln(row);
    }
    return buffer.toString();
  }

  /// Import transactions from CSV string. Expects header row. Returns number of imported rows.
  Future<int> importFromCsv(String csv) async {
    final lines = csv
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return 0;
    // remove header if present
    if (lines.first.toLowerCase().startsWith('id,')) lines.removeAt(0);

    var imported = 0;
    for (var line in lines) {
      // naive CSV split on commas respecting quoted fields
      final parts = _splitCsvLine(line);
      if (parts.length < 6) continue;
      try {
        final id = parts[0];
        final type = parts[1] == 'income'
            ? TransactionType.income
            : TransactionType.expense;
        final amount = double.parse(parts[2]);
        final category = parts[3];
        final description = parts[4];
        final date = DateTime.parse(parts[5]);
        final tx = Transaction(
          id: id,
          type: type,
          amount: amount,
          category: category,
          description: description,
          date: date,
        );
        await addTransaction(tx);
        imported++;
      } catch (_) {
        // skip malformed rows
        continue;
      }
    }
    return imported;
  }

  List<String> _splitCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        // if next is also quote, it's escaped quote
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++; // skip next
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString());
    return result.map((s) => s.replaceAll('"', '')).toList();
  }

  void setTypeFilter(TransactionType? type) {
    _typeFilter = type;
    fetchTransactions();
  }

  List<Transaction> getRecentTransactions(int count) {
    return _transactions.take(count).toList();
  }
}
