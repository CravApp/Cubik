// lib/features/tasks/presentation/screens/task_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/task_providers.dart';
import '../widgets/priority_badge.dart';

class TaskDetailScreen extends ConsumerWidget {
  final TaskEntity task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
      appBar: AppBar(
        title: const Text('Detalle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => context.push(AppRoutes.taskForm, extra: task),
          ),
          IconButton(
            icon: Icon(Icons.delete_rounded, color: AppTheme.kubikCoral),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('¿Eliminar tarea?', style: TextStyle(fontFamily: 'Poppins')),
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
              if (confirm == true) {
                if (!context.mounted) return;
                await ref.read(taskNotifierProvider.notifier).deleteTask(task);
                if (context.mounted) context.pop();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status urgente
            if (task.isUrgent)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.kubikCoral.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.kubikCoral.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Text('🚨', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 10),
                    Text('Tarea URGENTE – Alarma activa',
                      style: TextStyle(
                        color: AppTheme.kubikCoral,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().shakeX(hz: 2),

            // Título
            Text(task.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                color: task.isCompleted ? Colors.grey : null,
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 12),

            // Badges
            Wrap(
              spacing: 8,
              children: [
                PriorityBadge(priority: task.priority, large: true),
                if (task.isCompleted)
                  _Badge(label: '✅ Completada', color: AppTheme.accentGreen),
                if (task.isOverdue && !task.isCompleted)
                  _Badge(label: '⚠️ Vencida', color: Colors.deepOrange),
                if (task.isDueToday && !task.isCompleted)
                  _Badge(label: '📅 Hoy', color: AppTheme.kubikBlue),
              ],
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // Descripción
            if (task.description.isNotEmpty) ...[
              _InfoRow(
                icon: Icons.description_rounded,
                label: 'Descripción',
                value: task.description,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
            ],

            // Fecha de vencimiento
            _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'Fecha de vencimiento',
              value: DateFormat('EEEE, d MMMM yyyy  •  HH:mm', 'es_ES').format(task.dueDate),
              color: task.isOverdue ? Colors.deepOrange : null,
            ).animate().fadeIn(delay: 250.ms),

            const SizedBox(height: 16),

            // Recordatorio
            _InfoRow(
              icon: task.hasReminder ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
              label: 'Recordatorio',
              value: task.hasReminder
                  ? '${task.reminderMinutesBefore} minutos antes'
                  : 'Sin recordatorio',
              color: task.hasReminder ? AppTheme.kubikBlue : Colors.grey,
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 16),

            // Creada
            _InfoRow(
              icon: Icons.add_circle_outline_rounded,
              label: 'Creada',
              value: DateFormat('d MMM yyyy, HH:mm', 'es_ES').format(task.createdAt),
            ).animate().fadeIn(delay: 350.ms),

            if (task.isCompleted && task.completedAt != null) ...[
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.check_circle_rounded,
                label: 'Completada',
                value: DateFormat('d MMM yyyy, HH:mm', 'es_ES').format(task.completedAt!),
                color: AppTheme.accentGreen,
              ).animate().fadeIn(delay: 400.ms),
            ],

            const SizedBox(height: 40),

            // Botón completar / descompletar
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: task.isCompleted
                      ? Colors.grey.shade200
                      : AppTheme.accentGreen,
                  foregroundColor: task.isCompleted ? Colors.grey : Colors.white,
                ),
                icon: Icon(task.isCompleted
                    ? Icons.undo_rounded
                    : Icons.check_circle_rounded),
                label: Text(
                  task.isCompleted ? 'Marcar como pendiente' : 'Marcar como completada',
                ),
                onPressed: () async {
                  await ref.read(taskNotifierProvider.notifier).toggleCompletion(task);
                  if (context.mounted) context.pop();
                },
              ),
            ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _InfoRow({required this.icon, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color ?? AppTheme.kubikBlue.withValues(alpha: 0.7)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(
                fontFamily: 'Poppins', fontSize: 11,
                color: isDark ? const Color(0xFF8080A0) : Colors.grey.shade500,
              )),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(
                fontFamily: 'Poppins', fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color ?? (isDark ? Colors.white : const Color(0xFF1A1A2E)),
              )),
            ],
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(
        color: color, fontSize: 11,
        fontWeight: FontWeight.w600, fontFamily: 'Poppins',
      )),
    );
  }
}
