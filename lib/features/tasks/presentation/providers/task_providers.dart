// lib/features/tasks/presentation/providers/task_providers.dart
//
// ╔══════════════════════════════════════════════════════════════╗
// ║       PROVIDERS DE RIVERPOD – Gestión de Estado             ║
// ║  Capa: Presentation → Providers                             ║
// ║  Todos los providers de la feature de tareas viven aquí.    ║
// ╚══════════════════════════════════════════════════════════════╝

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/datasources/task_local_datasource.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../../../notifications/data/notification_service.dart';

// ─── Utilidades ──────────────────────────────────────────────────────────────
const _uuid = Uuid();

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDERS DE INFRAESTRUCTURA
// Proveen las instancias únicas del datasource, repositorio y servicio
// ─────────────────────────────────────────────────────────────────────────────

/// Datasource local (Hive). Inicializado en main() antes de runApp().
final taskDataSourceProvider = Provider<TaskLocalDataSource>((ref) {
  return TaskLocalDataSource();
});

/// Repositorio de tareas (implementación concreta)
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl(ref.watch(taskDataSourceProvider));
});

/// Servicio de notificaciones singleton
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// ─────────────────────────────────────────────────────────────────────────────
// STREAM PROVIDER – Lista reactiva de todas las tareas
// Se actualiza automáticamente cuando Hive cambia
// ─────────────────────────────────────────────────────────────────────────────
final allTasksStreamProvider = StreamProvider<List<TaskEntity>>((ref) {
  return ref.watch(taskRepositoryProvider).watchAllTasks();
});

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER DERIVADO – Tareas del día seleccionado
// ─────────────────────────────────────────────────────────────────────────────
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final tasksForSelectedDateProvider = Provider<List<TaskEntity>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final tasksAsync = ref.watch(allTasksStreamProvider);

  return tasksAsync.when(
    data: (tasks) => tasks.where((task) {
      return task.dueDate.year == selectedDate.year &&
          task.dueDate.month == selectedDate.month &&
          task.dueDate.day == selectedDate.day;
    }).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER DERIVADO – Estadísticas del dashboard
// ─────────────────────────────────────────────────────────────────────────────
final taskStatsProvider = Provider<TaskStats>((ref) {
  final tasksAsync = ref.watch(allTasksStreamProvider);

  return tasksAsync.when(
    data: (tasks) {
      final total = tasks.length;
      final completed = tasks.where((t) => t.isCompleted).length;
      final pending = tasks.where((t) => !t.isCompleted).length;
      final overdue = tasks.where((t) => t.isOverdue).length;
      final urgent = tasks.where((t) => t.isUrgent && !t.isCompleted).length;
      final dueToday = tasks.where((t) => t.isDueToday && !t.isCompleted).length;
      return TaskStats(
        total: total,
        completed: completed,
        pending: pending,
        overdue: overdue,
        urgent: urgent,
        dueToday: dueToday,
      );
    },
    loading: () => TaskStats.empty(),
    error: (_, __) => TaskStats.empty(),
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFIER – Maneja CRUD de tareas con efectos secundarios (notificaciones)
// ─────────────────────────────────────────────────────────────────────────────
class TaskNotifier extends AsyncNotifier<void> {
  late TaskRepository _repository;
  late NotificationService _notificationService;

  @override
  Future<void> build() async {
    _repository = ref.watch(taskRepositoryProvider);
    _notificationService = ref.watch(notificationServiceProvider);
  }

  // ─── Crear tarea ──────────────────────────────────────────────────
  Future<void> addTask({
    required String title,
    String description = '',
    required DateTime dueDate,
    TaskPriority priority = TaskPriority.medium,
    bool isUrgent = false,
    bool hasReminder = true,
    int reminderMinutesBefore = 30,
  }) async {
    state = const AsyncLoading();

    final notificationId = _uuid.v4().hashCode.abs() % 2147483647;

    final newTask = TaskEntity(
      id: _uuid.v4(),
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      isUrgent: isUrgent,
      hasReminder: hasReminder,
      reminderMinutesBefore: reminderMinutesBefore,
      createdAt: DateTime.now(),
      notificationId: notificationId,
    );

    state = await AsyncValue.guard(() async {
      await _repository.addTask(newTask);

      // Programar notificación si la tarea tiene recordatorio
      if (hasReminder) {
        if (isUrgent) {
          // Alarma urgente: persistente con fullScreenIntent
          await _notificationService.showUrgentAlarm(
            notificationId: notificationId,
            taskTitle: title,
            taskDescription: description,
            dueDate: dueDate,
          );
        } else {
          // Recordatorio normal N minutos antes
          await _notificationService.scheduleTaskReminder(
            notificationId: notificationId,
            taskTitle: title,
            taskDescription: description,
            dueDate: dueDate,
            minutesBefore: reminderMinutesBefore,
          );
        }
      }
    });
  }

  // ─── Actualizar tarea ─────────────────────────────────────────────
  Future<void> updateTask(TaskEntity task) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // Cancelar notificación anterior y reprogramar
      if (task.notificationId != null) {
        await _notificationService.cancelNotification(task.notificationId!);
      }

      await _repository.updateTask(task);

      // Reprogramar notificación con los nuevos datos
      if (task.hasReminder && !task.isCompleted) {
        if (task.isUrgent) {
          await _notificationService.showUrgentAlarm(
            notificationId: task.notificationId ?? generateNotificationId(task.id),
            taskTitle: task.title,
            taskDescription: task.description,
            dueDate: task.dueDate,
          );
        } else {
          await _notificationService.scheduleTaskReminder(
            notificationId: task.notificationId ?? generateNotificationId(task.id),
            taskTitle: task.title,
            taskDescription: task.description,
            dueDate: task.dueDate,
            minutesBefore: task.reminderMinutesBefore,
          );
        }
      }
    });
  }

  // ─── Eliminar tarea ───────────────────────────────────────────────
  Future<void> deleteTask(TaskEntity task) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // Cancelar la notificación antes de eliminar
      if (task.notificationId != null) {
        await _notificationService.cancelNotification(task.notificationId!);
      }
      await _repository.deleteTask(task.id);
    });
  }

  // ─── Alternar completado ──────────────────────────────────────────
  Future<void> toggleCompletion(TaskEntity task) async {
    state = await AsyncValue.guard(() async {
      await _repository.toggleTaskCompletion(task.id);
      // Si se completa, cancelar su recordatorio
      if (!task.isCompleted && task.notificationId != null) {
        await _notificationService.cancelNotification(task.notificationId!);
      }
    });
  }
}

/// Provider del notifier de tareas
final taskNotifierProvider =
    AsyncNotifierProvider<TaskNotifier, void>(TaskNotifier.new);

// ─────────────────────────────────────────────────────────────────────────────
// MODELO DE ESTADÍSTICAS (para el Dashboard)
// ─────────────────────────────────────────────────────────────────────────────
class TaskStats {
  final int total;
  final int completed;
  final int pending;
  final int overdue;
  final int urgent;
  final int dueToday;

  const TaskStats({
    required this.total,
    required this.completed,
    required this.pending,
    required this.overdue,
    required this.urgent,
    required this.dueToday,
  });

  factory TaskStats.empty() => const TaskStats(
        total: 0,
        completed: 0,
        pending: 0,
        overdue: 0,
        urgent: 0,
        dueToday: 0,
      );

  double get completionRate =>
      total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER DE FILTROS (para la pantalla de lista de tareas)
// ─────────────────────────────────────────────────────────────────────────────
enum TaskFilter { all, pending, completed, urgent, overdue }

final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);

final filteredTasksProvider = Provider<List<TaskEntity>>((ref) {
  final filter = ref.watch(taskFilterProvider);
  final tasksAsync = ref.watch(allTasksStreamProvider);

  return tasksAsync.when(
    data: (tasks) {
      switch (filter) {
        case TaskFilter.all:
          return tasks;
        case TaskFilter.pending:
          return tasks.where((t) => !t.isCompleted).toList();
        case TaskFilter.completed:
          return tasks.where((t) => t.isCompleted).toList();
        case TaskFilter.urgent:
          return tasks.where((t) => t.isUrgent && !t.isCompleted).toList();
        case TaskFilter.overdue:
          return tasks.where((t) => t.isOverdue).toList();
      }
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER DE TEMA (modo oscuro / claro)
// ─────────────────────────────────────────────────────────────────────────────
final themeModeProvider = StateProvider<bool>((ref) => false); // false = claro
