// lib/features/tasks/presentation/widgets/task_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/task_entity.dart';
import 'priority_badge.dart';

class TaskCard extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final bool isUrgentStyle;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    this.isUrgentStyle = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverdue = task.isOverdue;

    Color borderColor = isDark ? AppTheme.dividerDark : AppTheme.dividerLight;
    if (isUrgentStyle) borderColor = AppTheme.kubikCoral.withValues(alpha: 0.5);
    if (isOverdue) borderColor = Colors.deepOrange.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: isUrgentStyle
              ? [BoxShadow(
                  color: AppTheme.kubikCoral.withValues(alpha: 0.12),
                  blurRadius: 12, offset: const Offset(0, 4),
                )]
              : [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8, offset: const Offset(0, 2),
                )],
        ),
        child: Row(
          children: [
            // Checkbox animado
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: task.isCompleted ? AppTheme.accentGreen : Colors.transparent,
                  border: Border.all(
                    color: task.isCompleted
                        ? AppTheme.accentGreen
                        : _priorityColor(task.priority),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: task.isCompleted
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                    : null,
              ),
            ),

            const SizedBox(width: 12),

            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Urgente indicator
                      if (task.isUrgent) ...[
                        const Text('🚨', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: task.isCompleted
                                ? Colors.grey
                                : (isDark ? Colors.white : const Color(0xFF1A1A2E)),
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.description,
                      style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 11,
                        color: isDark ? const Color(0xFF8080A0) : Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      PriorityBadge(priority: task.priority),
                      const SizedBox(width: 8),
                      Icon(
                        isOverdue ? Icons.timer_off_rounded : Icons.schedule_rounded,
                        size: 12,
                        color: isOverdue ? Colors.deepOrange : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _formatDueDate(task),
                        style: TextStyle(
                          fontFamily: 'Poppins', fontSize: 11,
                          color: isOverdue ? Colors.deepOrange : Colors.grey.shade500,
                          fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Menú o flecha
            if (onDelete != null)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade400, size: 18),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'delete', child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text('Eliminar', style: TextStyle(fontFamily: 'Poppins')),
                    ],
                  )),
                ],
                onSelected: (val) { if (val == 'delete') onDelete!(); },
              )
            else
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 18),
          ],
        ),
      ),
    );
  }

  String _formatDueDate(TaskEntity task) {
    if (task.isDueToday) {
      return 'Hoy ${DateFormat('HH:mm').format(task.dueDate)}';
    }
    if (task.daysRemaining == 1) return 'Mañana';
    if (task.daysRemaining < 0) return 'Venció hace ${task.daysRemaining.abs()}d';
    return DateFormat('d MMM', 'es_ES').format(task.dueDate);
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low: return AppTheme.priorityLow;
      case TaskPriority.medium: return AppTheme.priorityMedium;
      case TaskPriority.high: return AppTheme.priorityHigh;
    }
  }
}
