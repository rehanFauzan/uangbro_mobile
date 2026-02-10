import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'savings_target_model.g.dart';

@HiveType(typeId: 2)
class SavingsTarget extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double targetAmount;

  @HiveField(3)
  double currentProgress;

  @HiveField(4)
  DateTime deadline;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  String? userId;

  @HiveField(7)
  bool isCompleted;

  SavingsTarget({
    String? id,
    required this.name,
    required this.targetAmount,
    this.currentProgress = 0,
    required this.deadline,
    DateTime? createdAt,
    this.isCompleted = false,
    this.userId,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  double get remainingAmount => targetAmount - currentProgress;

  double get progressPercentage {
    if (targetAmount <= 0) return 0;
    double percentage = (currentProgress / targetAmount) * 100;
    return percentage.clamp(0, 100);
  }

  bool get isOverdue {
    return !isCompleted && DateTime.now().isAfter(deadline);
  }

  int get daysRemaining {
    final now = DateTime.now();
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);
    final today = DateTime(now.year, now.month, now.day);
    return deadlineDate.difference(today).inDays;
  }

  factory SavingsTarget.fromJson(Map<String, dynamic> json) {
    return SavingsTarget(
      id: json['id'],
      name: json['name'],
      targetAmount: double.parse(json['targetAmount'].toString()),
      currentProgress: double.parse(json['currentProgress'].toString()),
      deadline: DateTime.parse(json['deadline']),
      createdAt: DateTime.parse(json['createdAt']),
      isCompleted: json['isCompleted'] ?? false,
      userId: json['userId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentProgress': currentProgress,
      'deadline': deadline.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted,
      'userId': userId,
    };
  }

  SavingsTarget copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentProgress,
    DateTime? deadline,
    bool? isCompleted,
    String? userId,
  }) {
    return SavingsTarget(
      id: id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentProgress: currentProgress ?? this.currentProgress,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      userId: userId ?? this.userId,
    );
  }
}
