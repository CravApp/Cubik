// GENERATED CODE - DO NOT MODIFY BY HAND
// Adaptador Hive generado manualmente para task_entity.dart
// (evita correr build_runner en el entorno de preview)

part of 'task_entity.dart';

// ────────────────────────────────────────────────────────────────────────────────
// TypeAdapter para TaskPriority (typeId: 1)
// ────────────────────────────────────────────────────────────────────────────────
class TaskPriorityAdapter extends TypeAdapter<TaskPriority> {
  @override
  final int typeId = 1;

  @override
  TaskPriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskPriority.low;
      case 1:
        return TaskPriority.medium;
      case 2:
        return TaskPriority.high;
      default:
        return TaskPriority.medium;
    }
  }

  @override
  void write(BinaryWriter writer, TaskPriority obj) {
    switch (obj) {
      case TaskPriority.low:
        writer.writeByte(0);
        break;
      case TaskPriority.medium:
        writer.writeByte(1);
        break;
      case TaskPriority.high:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskPriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// ────────────────────────────────────────────────────────────────────────────────
// TypeAdapter para TaskEntity (typeId: 0)
// ────────────────────────────────────────────────────────────────────────────────
class TaskEntityAdapter extends TypeAdapter<TaskEntity> {
  @override
  final int typeId = 0;

  @override
  TaskEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskEntity(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String? ?? '',
      dueDate: fields[3] as DateTime,
      priority: fields[4] as TaskPriority? ?? TaskPriority.medium,
      isCompleted: fields[5] as bool? ?? false,
      isUrgent: fields[6] as bool? ?? false,
      hasReminder: fields[7] as bool? ?? true,
      reminderMinutesBefore: fields[8] as int? ?? 30,
      createdAt: fields[9] as DateTime,
      completedAt: fields[10] as DateTime?,
      notificationId: fields[11] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskEntity obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.dueDate)
      ..writeByte(4)
      ..write(obj.priority)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.isUrgent)
      ..writeByte(7)
      ..write(obj.hasReminder)
      ..writeByte(8)
      ..write(obj.reminderMinutesBefore)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.completedAt)
      ..writeByte(11)
      ..write(obj.notificationId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
