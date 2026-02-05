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
      print("Error fetching transactions: $e");
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

  void setTypeFilter(TransactionType? type) {
    _typeFilter = type;
    fetchTransactions();
  }

  List<Transaction> getRecentTransactions(int count) {
    return _transactions.take(count).toList();
  }
}
