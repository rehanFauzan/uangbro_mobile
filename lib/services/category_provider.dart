import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CategoryProvider with ChangeNotifier {
  static const String _boxName = 'categories_box';

  List<String> _categories = [];
  List<String> get categories => _categories;

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_boxName);
    final box = Hive.box<String>(_boxName);
    _categories = box.values.toList();
    // If no categories exist, seed some defaults
    if (_categories.isEmpty) {
      _categories = [
        'Makan',
        'Transport',
        'Belanja',
        'Tagihan',
        'Gaji',
        'Investasi',
      ];
      await box.clear();
      var i = 0;
      for (var c in _categories) {
        await box.put(i.toString(), c);
        i++;
      }
    }
    notifyListeners();
  }

  Future<void> addCategory(String name) async {
    final box = Hive.box<String>(_boxName);
    await box.put(DateTime.now().millisecondsSinceEpoch.toString(), name);
    _categories = box.values.toList();
    notifyListeners();
  }

  Future<void> updateCategory(int index, String newName) async {
    final box = Hive.box<String>(_boxName);
    final key = box.keyAt(index);
    await box.put(key, newName);
    _categories = box.values.toList();
    notifyListeners();
  }

  Future<void> deleteCategory(int index) async {
    final box = Hive.box<String>(_boxName);
    final key = box.keyAt(index);
    await box.delete(key);
    _categories = box.values.toList();
    notifyListeners();
  }
}
