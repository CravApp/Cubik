// lib/features/calendar/presentation/screens/calendar_screen.dart
//
// ╔══════════════════════════════════════════════════════════════╗
// ║          PANTALLA DE CALENDARIO                             ║
// ║  Vista mensual donde se visualizan las tareas por día.      ║
// ║  Al tocar un día, muestra sus tareas en la parte inferior.  ║
// ╚══════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../../tasks/presentation/widgets/task_card.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _currentMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _selectedDay = now;
    // Actualiza el provider con el día actual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedDateProvider.notifier).state = _selectedDay;
    });
  }

  void _prevMonth() => setState(() {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      });

  void _onDaySelected(DateTime day) {
    setState(() => _selectedDay = day);
    ref.read(selectedDateProvider.notifier).state = day;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allTasksAsync = ref.watch(allTasksStreamProvider);
    final selectedTasks = ref.watch(tasksForSelectedDateProvider);

    // Mapa de día → cantidad de tareas (para los indicadores del calendario)
    final taskCountByDay = <int, int>{};
    if (allTasksAsync.valueOrNull != null) {
      for (final task in allTasksAsync.valueOrNull!) {
        if (task.dueDate.year == _currentMonth.year &&
            task.dueDate.month == _currentMonth.month) {
          taskCountByDay[task.dueDate.day] =
              (taskCountByDay[task.dueDate.day] ?? 0) + 1;
        }
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  Text('Calendario',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _onDaySelected(DateTime.now()),
                    icon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.kubikBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Hoy',
                        style: TextStyle(
                          color: AppTheme.kubikBlue, fontSize: 13,
                          fontWeight: FontWeight.w600, fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 16),

            // ── Navegación de mes ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _NavButton(icon: Icons.chevron_left_rounded, onTap: _prevMonth),
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy', 'es_ES').format(_currentMonth),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        textBaseline: TextBaseline.alphabetic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  _NavButton(icon: Icons.chevron_right_rounded, onTap: _nextMonth),
                ],
              ).animate().fadeIn(delay: 100.ms),
            ),

            const SizedBox(height: 16),

            // ── Días de la semana ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['L','M','X','J','V','S','D'].map((d) => Expanded(
                  child: Center(
                    child: Text(d,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: d == 'D' || d == 'S'
                            ? AppTheme.kubikBlue
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                )).toList(),
              ).animate().fadeIn(delay: 150.ms),
            ),

            const SizedBox(height: 8),

            // ── Grid del calendario ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _CalendarGrid(
                currentMonth: _currentMonth,
                selectedDay: _selectedDay,
                taskCountByDay: taskCountByDay,
                onDaySelected: _onDaySelected,
              ).animate().fadeIn(delay: 200.ms),
            ),

            const SizedBox(height: 16),

            // ── Divisor ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    'Tareas: ${DateFormat('d MMMM', 'es_ES').format(_selectedDay)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.kubikBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (selectedTasks.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.kubikBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${selectedTasks.length}',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 11,
                          fontWeight: FontWeight.w700, fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Lista de tareas del día seleccionado ───────────────
            Expanded(
              child: selectedTasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_available_rounded,
                            size: 48, color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text('Sin tareas este día',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontFamily: 'Poppins', fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: selectedTasks.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TaskCard(
                          task: selectedTasks[i],
                          onTap: () => context.push(AppRoutes.taskDetail, extra: selectedTasks[i]),
                          onToggle: () => ref.read(taskNotifierProvider.notifier).toggleCompletion(selectedTasks[i]),
                          onDelete: () => ref.read(taskNotifierProvider.notifier).deleteTask(selectedTasks[i]),
                        ).animate().fadeIn(delay: Duration(milliseconds: i * 60)),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.taskForm),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ─── Grid del calendario ──────────────────────────────────────────────────────
class _CalendarGrid extends StatelessWidget {
  final DateTime currentMonth;
  final DateTime selectedDay;
  final Map<int, int> taskCountByDay;
  final Function(DateTime) onDaySelected;

  const _CalendarGrid({
    required this.currentMonth,
    required this.selectedDay,
    required this.taskCountByDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    // Calcula el primer día del mes y cuántos días tiene
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;

    // weekday: 1=Lunes … 7=Domingo → necesitamos offset para empezar la grilla en Lunes
    int startOffset = firstDay.weekday - 1; // 0=Lunes
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final now = DateTime.now();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: rows * 7,
      itemBuilder: (context, index) {
        final day = index - startOffset + 1;
        if (day < 1 || day > daysInMonth) return const SizedBox();

        final date = DateTime(currentMonth.year, currentMonth.month, day);
        final isSelected = date.day == selectedDay.day &&
            date.month == selectedDay.month &&
            date.year == selectedDay.year;
        final isToday = date.day == now.day &&
            date.month == now.month &&
            date.year == now.year;
        final taskCount = taskCountByDay[day] ?? 0;

        return GestureDetector(
          onTap: () => onDaySelected(date),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.kubikBlue
                  : isToday
                      ? AppTheme.kubikBlue.withValues(alpha: 0.1)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: isSelected || isToday
                        ? FontWeight.w700
                        : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : isToday
                            ? AppTheme.kubikBlue
                            : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                // Indicador de tareas (puntos)
                if (taskCount > 0)
                  Positioned(
                    bottom: 3,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        taskCount.clamp(1, 3),
                        (_) => Container(
                          width: 4, height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.7)
                                : AppTheme.kubikBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
          ),
        ),
        child: Icon(icon, size: 20,
          color: isDark ? Colors.white : const Color(0xFF3D3D5C),
        ),
      ),
    );
  }
}
