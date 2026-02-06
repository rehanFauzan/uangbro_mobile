import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}

@HiveType(typeId: 1)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final TransactionType type;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String category;

  @HiveField(4)
  String description;

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  String? userId;

  Transaction({
    String? id,
    required this.type,
    required this.amount,
    required this.category,
    this.description = '',
    required this.date,
    this.userId,
  }) : id = id ?? const Uuid().v4();

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: json['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      amount: double.parse(json['amount'].toString()),
      category: json['category'],
      description: json['description'] ?? '',
      date: DateTime.parse(json['date']),
      userId: json.containsKey('user_id')
          ? (json['user_id']?.toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'user_id': userId,
    };
  }
}
