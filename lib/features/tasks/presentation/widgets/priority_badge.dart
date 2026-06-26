// lib/features/tasks/presentation/widgets/priority_badge.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/task_entity.dart';

class PriorityBadge extends StatelessWidget {
  final TaskPriority priority;
  final bool large;

  const PriorityBadge({super.key, required this.priority, this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 6,
        vertical: large ? 5 : 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: large ? 7 : 5,
            height: large ? 7 : 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              color: color,
              fontSize: large ? 12 : 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Color get _color {
    switch (priority) {
      case TaskPriority.low: return AppTheme.priorityLow;
      case TaskPriority.medium: return AppTheme.priorityMedium;
      case TaskPriority.high: return AppTheme.priorityHigh;
    }
  }

  String get _label {
    switch (priority) {
      case TaskPriority.low: return 'Baja';
      case TaskPriority.medium: return 'Media';
      case TaskPriority.high: return 'Alta';
    }
  }
}
