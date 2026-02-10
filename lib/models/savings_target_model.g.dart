// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'savings_target_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavingsTargetAdapter extends TypeAdapter<SavingsTarget> {
  @override
  final int typeId = 2;

  @override
  SavingsTarget read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavingsTarget(
      id: fields[0] as String?,
      name: fields[1] as String,
      targetAmount: fields[2] as double,
      currentProgress: fields[3] as double,
      deadline: fields[4] as DateTime,
      createdAt: fields[5] as DateTime,
      userId: fields[6] as String?,
      isCompleted: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SavingsTarget obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.targetAmount)
      ..writeByte(3)
      ..write(obj.currentProgress)
      ..writeByte(4)
      ..write(obj.deadline)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.userId)
      ..writeByte(7)
      ..write(obj.isCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingsTargetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
