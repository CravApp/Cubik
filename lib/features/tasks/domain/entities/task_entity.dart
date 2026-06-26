// lib/features/tasks/domain/entities/task_entity.dart
//
// ╔══════════════════════════════════════════════════════════════╗
// ║           ENTIDAD DE DOMINIO – TaskEntity                   ║
// ║  Capa: Domain → Entities                                    ║
// ║  Esta clase es PURA Dart, sin dependencias de frameworks.   ║
// ║  Representa el concepto de "Tarea" en nuestra app.          ║
// ╚══════════════════════════════════════════════════════════════╝

import 'package:hive/hive.dart';

part 'task_entity.g.dart'; // Generado por hive_generator

// ─── Enumeración de Prioridad ─────────────────────────────────────────────────
/// Define los tres niveles de prioridad disponibles para una tarea.
/// [HiveType(typeId: 1)] reserva el typeId=1 para Hive.
@HiveType(typeId: 1)
enum TaskPriority {
  @HiveField(0)
  low, // Prioridad baja – color verde

  @HiveField(1)
  medium, // Prioridad media – color ámbar

  @HiveField(2)
  high, // Prioridad alta – color rojo/coral
}

// ─── Modelo Principal de Tarea ────────────────────────────────────────────────
/// [HiveType(typeId: 0)] → este es el typeId principal para TaskEntity.
/// Todos los campos se mapean con @HiveField para serialización automática.
@HiveType(typeId: 0)
class TaskEntity extends HiveObject {
  @HiveField(0)
  final String id; // UUID único generado al crear la tarea

  @HiveField(1)
  String title; // Título corto y descriptivo

  @HiveField(2)
  String description; // Descripción detallada (puede estar vacía)

  @HiveField(3)
  DateTime dueDate; // Fecha y hora límite de la tarea

  @HiveField(4)
  TaskPriority priority; // Nivel de prioridad

  @HiveField(5)
  bool isCompleted; // true = tarea completada

  @HiveField(6)
  bool isUrgent; // true = activa alarma persistente (sonido continuo)

  @HiveField(7)
  bool hasReminder; // true = tiene notificación programada

  @HiveField(8)
  int reminderMinutesBefore; // Cuántos minutos antes recordar (5,10,15,30,60…)

  @HiveField(9)
  DateTime createdAt; // Fecha de creación (para ordenar y estadísticas)

  @HiveField(10)
  DateTime? completedAt; // Fecha en que se marcó como completada (nullable)

  @HiveField(11)
  int? notificationId; // ID de la notificación local (para cancelarla)

  TaskEntity({
    required this.id,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
    this.isUrgent = false,
    this.hasReminder = true,
    this.reminderMinutesBefore = 30,
    required this.createdAt,
    this.completedAt,
    this.notificationId,
  });

  // ─── Factory: copia con campos modificados ──────────────────────────
  /// Devuelve un nuevo TaskEntity con los campos que se pasen modificados.
  /// Útil para actualizaciones inmutables desde los providers.
  TaskEntity copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    bool? isCompleted,
    bool? isUrgent,
    bool? hasReminder,
    int? reminderMinutesBefore,
    DateTime? completedAt,
    int? notificationId,
  }) {
    return TaskEntity(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      isUrgent: isUrgent ?? this.isUrgent,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  // ─── Getters computados ─────────────────────────────────────────────
  /// true si la fecha límite ya pasó y la tarea no está completada
  bool get isOverdue =>
      !isCompleted && dueDate.isBefore(DateTime.now());

  /// true si vence hoy
  bool get isDueToday {
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  /// Devuelve el número de días restantes (negativo si ya venció)
  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  @override
  String toString() =>
      'TaskEntity(id: $id, title: $title, dueDate: $dueDate, priority: $priority)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
