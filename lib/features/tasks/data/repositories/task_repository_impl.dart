// lib/features/tasks/data/repositories/task_repository_impl.dart
//
// ╔══════════════════════════════════════════════════════════════╗
// ║      IMPLEMENTACIÓN del Repositorio de Tareas               ║
// ║  Capa: Data → Repositories                                  ║
// ║  Conecta el contrato (dominio) con el datasource (Hive).    ║
// ╚══════════════════════════════════════════════════════════════╝

import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_datasource.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource _dataSource;

  const TaskRepositoryImpl(this._dataSource);

  @override
  Future<List<TaskEntity>> getAllTasks() async {
    return _dataSource.getAllTasks();
  }

  @override
  Future<List<TaskEntity>> getTasksByDate(DateTime date) async {
    return _dataSource.getTasksByDate(date);
  }

  @override
  Future<List<TaskEntity>> getTasksByPriority(TaskPriority priority) async {
    return _dataSource.getTasksByPriority(priority);
  }

  @override
  Future<List<TaskEntity>> getPendingTasks() async {
    return _dataSource.getPendingTasks();
  }

  @override
  Future<void> addTask(TaskEntity task) async {
    await _dataSource.saveTask(task);
  }

  @override
  Future<void> updateTask(TaskEntity task) async {
    await _dataSource.saveTask(task);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _dataSource.deleteTask(taskId);
  }

  @override
  Future<void> toggleTaskCompletion(String taskId) async {
    await _dataSource.toggleCompletion(taskId);
  }

  @override
  Stream<List<TaskEntity>> watchAllTasks() {
    return _dataSource.watchAllTasks();
  }
}
