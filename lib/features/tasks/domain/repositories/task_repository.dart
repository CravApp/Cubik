// lib/features/tasks/domain/repositories/task_repository.dart
//
// ╔══════════════════════════════════════════════════════════════╗
// ║        CONTRATO (INTERFAZ) del Repositorio de Tareas        ║
// ║  Capa: Domain → Repositories                                ║
// ║  Define QUÉ operaciones existen, sin importar CÓMO          ║
// ║  se implementan (Hive, SQLite, API remota…).                ║
// ╚══════════════════════════════════════════════════════════════╝

import '../entities/task_entity.dart';

abstract class TaskRepository {
  /// Retorna todas las tareas guardadas localmente
  Future<List<TaskEntity>> getAllTasks();

  /// Retorna tareas filtradas por fecha (para la vista de calendario)
  Future<List<TaskEntity>> getTasksByDate(DateTime date);

  /// Retorna tareas filtradas por prioridad
  Future<List<TaskEntity>> getTasksByPriority(TaskPriority priority);

  /// Retorna solo las tareas pendientes (no completadas)
  Future<List<TaskEntity>> getPendingTasks();

  /// Agrega una nueva tarea al repositorio
  Future<void> addTask(TaskEntity task);

  /// Actualiza los datos de una tarea existente
  Future<void> updateTask(TaskEntity task);

  /// Elimina una tarea por su ID
  Future<void> deleteTask(String taskId);

  /// Cambia el estado completado de la tarea
  Future<void> toggleTaskCompletion(String taskId);

  /// Escucha cambios reactivos en todas las tareas
  Stream<List<TaskEntity>> watchAllTasks();
}
