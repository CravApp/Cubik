// lib/features/tasks/presentation/screens/task_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/task_providers.dart';
import '../widgets/task_card.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(taskFilterProvider);
    final tasks = ref.watch(filteredTasksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filtros ──────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: TaskFilter.values.map((f) {
                final isSelected = filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(_filterLabel(f)),
                    onSelected: (_) => ref.read(taskFilterProvider.notifier).state = f,
                    selectedColor: AppTheme.kubikBlue.withValues(alpha: 0.15),
                    checkmarkColor: AppTheme.kubikBlue,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.kubikBlue : null,
                      fontWeight: isSelected ? FontWeight.w600 : null,
                      fontFamily: 'Poppins', fontSize: 12,
                    ),
                  ).animate().fadeIn(delay: 50.ms),
                );
              }).toList(),
            ),
          ),

          // ── Lista de tareas ──────────────────────────────────────
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          filter == TaskFilter.all
                              ? 'Aún no tienes tareas\n¡Crea una ahora!'
                              : 'No hay tareas en este filtro',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontFamily: 'Poppins', fontSize: 16,
                          ),
                        ),
                        if (filter == TaskFilter.all) ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.push(AppRoutes.taskForm),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Crear primera tarea'),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      return Dismissible(
                        key: Key(tasks[i].id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppTheme.kubikCoral.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_rounded, color: AppTheme.kubikCoral),
                        ),
                        confirmDismiss: (_) => _confirmDelete(context),
                        onDismissed: (_) =>
                            ref.read(taskNotifierProvider.notifier).deleteTask(tasks[i]),
                        child: TaskCard(
                          task: tasks[i],
                          isUrgentStyle: tasks[i].isUrgent,
                          onTap: () => context.push(AppRoutes.taskDetail, extra: tasks[i]),
                          onToggle: () => ref.read(taskNotifierProvider.notifier).toggleCompletion(tasks[i]),
                          onDelete: () => ref.read(taskNotifierProvider.notifier).deleteTask(tasks[i]),
                        ).animate().fadeIn(delay: Duration(milliseconds: i * 40)),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.taskForm),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
      ),
    );
  }

  String _filterLabel(TaskFilter f) {
    switch (f) {
      case TaskFilter.all: return 'Todas';
      case TaskFilter.pending: return 'Pendientes';
      case TaskFilter.completed: return '✅ Completadas';
      case TaskFilter.urgent: return '🚨 Urgentes';
      case TaskFilter.overdue: return '⚠️ Vencidas';
    }
  }

  Future<bool?> _confirmDelete(BuildContext context) => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('¿Eliminar tarea?', style: TextStyle(fontFamily: 'Poppins')),
      content: const Text('Esta acción no se puede deshacer.', style: TextStyle(fontFamily: 'Poppins')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kubikCoral),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
}
