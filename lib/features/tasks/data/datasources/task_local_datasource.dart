// lib/features/tasks/data/datasources/task_local_datasource.dart
//
// ╔══════════════════════════════════════════════════════════════╗
// ║         DATASOURCE LOCAL – Implementación con Hive          ║
// ║  Capa: Data → DataSources                                   ║
// ║  Aquí vive TODA la lógica de acceso a la base de datos Hive ║
// ╚══════════════════════════════════════════════════════════════╝

import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/task_entity.dart';

/// Nombre de la caja (tabla) de Hive donde se almacenan las tareas
const String kTaskBoxName = 'tasks_box';

class TaskLocalDataSource {
  // ── Referencia a la caja de Hive ────────────────────────────────
  late Box<TaskEntity> _taskBox;

  /// Inicializa Hive y abre la caja de tareas.
  /// Debe llamarse ANTES de usar cualquier método de esta clase.
  /// Se llama una sola vez desde main.dart.
  Future<void> init() async {
    await Hive.initFlutter(); // Inicializa Hive en el directorio de documentos

    // Registrar adaptadores (solo una vez, protegido con isRegistered)
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskEntityAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TaskPriorityAdapter());
    }

    // Abre la caja tipada con TaskEntity
    _taskBox = await Hive.openBox<TaskEntity>(kTaskBoxName);
  }

  // ─── CRUD ────────────────────────────────────────────────────────

  /// Guarda una tarea usando su ID como clave para búsqueda O(1)
  Future<void> saveTask(TaskEntity task) async {
    await _taskBox.put(task.id, task);
  }

  /// Devuelve todas las tareas ordenadas por fecha de vencimiento
  List<TaskEntity> getAllTasks() {
    final tasks = _taskBox.values.toList();
    tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return tasks;
  }

  /// Devuelve las tareas de un día específico (sin considerar hora)
  List<TaskEntity> getTasksByDate(DateTime date) {
    return _taskBox.values.where((task) {
      return task.dueDate.year == date.year &&
          task.dueDate.month == date.month &&
          task.dueDate.day == date.day;
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  /// Devuelve tareas filtradas por prioridad
  List<TaskEntity> getTasksByPriority(TaskPriority priority) {
    return _taskBox.values
        .where((t) => t.priority == priority)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  /// Devuelve solo las tareas pendientes (no completadas)
  List<TaskEntity> getPendingTasks() {
    return _taskBox.values
        .where((t) => !t.isCompleted)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  /// Elimina una tarea por su ID
  Future<void> deleteTask(String taskId) async {
    await _taskBox.delete(taskId);
  }

  /// Alterna el estado completado de una tarea
  Future<void> toggleCompletion(String taskId) async {
    final task = _taskBox.get(taskId);
    if (task != null) {
      task.isCompleted = !task.isCompleted;
      task.completedAt = task.isCompleted ? DateTime.now() : null;
      await task.save(); // HiveObject.save() persiste automáticamente
    }
  }

  // ─── Stream reactivo ─────────────────────────────────────────────
  /// Emite una nueva lista cada vez que la caja de Hive cambia.
  /// Perfecto para mantener la UI siempre sincronizada.
  Stream<List<TaskEntity>> watchAllTasks() {
    return _taskBox.watch().map((_) => getAllTasks());
  }

  /// Acceso directo a la caja (para uso avanzado en providers)
  Box<TaskEntity> get box => _taskBox;
}
