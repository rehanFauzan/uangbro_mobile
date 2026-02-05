import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';

class DatabaseService {
  static const String boxName = 'transactions_box';

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(TransactionAdapter());
    await Hive.openBox<Transaction>(boxName);
  }

  Box<Transaction> getBox() {
    return Hive.box<Transaction>(boxName);
  }

  Future<void> addTransaction(Transaction transaction) async {
    final box = getBox();
    await box.add(transaction);
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    await transaction.delete();
  }

  Future<void> clearAll() async {
    final box = getBox();
    await box.clear();
  }
}
