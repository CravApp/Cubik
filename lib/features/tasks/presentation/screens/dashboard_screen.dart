// lib/features/tasks/presentation/screens/dashboard_screen.dart
//
// ╔══════════════════════════════════════════════════════════════╗
// ║          PANTALLA PRINCIPAL – Dashboard                     ║
// ║  Muestra: estadísticas, tareas urgentes, tareas de hoy,    ║
// ║  próximas tareas y accesos rápidos.                         ║
// ║  Conectada a Riverpod (taskStatsProvider, allTasksStream).  ║
// ╚══════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/task_providers.dart';
import '../widgets/task_card.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(taskStatsProvider);
    final allTasksAsync = ref.watch(allTasksStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Tareas urgentes pendientes
    final urgentTasks = allTasksAsync.valueOrNull
        ?.where((t) => t.isUrgent && !t.isCompleted)
        .take(3)
        .toList() ?? [];

    // Tareas de hoy
    final todayTasks = allTasksAsync.valueOrNull
        ?.where((t) => t.isDueToday && !t.isCompleted)
        .take(5)
        .toList() ?? [];

    // Tareas próximas (no hoy, no completadas, ordenadas)
    final upcomingTasks = allTasksAsync.valueOrNull
        ?.where((t) => !t.isDueToday && !t.isCompleted && !t.isOverdue)
        .take(3)
        .toList() ?? [];

    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    final dateStr = DateFormat('EEEE, d MMMM', 'es_ES').format(now);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.kubikCoral,
          onRefresh: () async => ref.invalidate(allTasksStreamProvider),
          child: CustomScrollView(
            slivers: [
              // ── Header ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(greeting,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 2),
                            Text('Dashboard',
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            Text(dateStr,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.kubikCoral,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Avatar / perfil con logo Kubik
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.profile),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.kubikCoral, AppTheme.kubikBlue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.kubikBlue.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Image.asset(
                            'assets/images/kubik_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Tarjetas de estadísticas ────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progreso circular
                      _ProgressCard(stats: stats, isDark: isDark)
                          .animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 16),

                      // Grid de estadísticas
                      Row(
                        children: [
                          Expanded(child: StatCard(
                            label: 'Pendientes',
                            value: stats.pending.toString(),
                            icon: Icons.pending_actions_rounded,
                            color: AppTheme.priorityMedium,
                          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2, end: 0)),
                          const SizedBox(width: 12),
                          Expanded(child: StatCard(
                            label: 'Completadas',
                            value: stats.completed.toString(),
                            icon: Icons.check_circle_rounded,
                            color: AppTheme.accentGreen,
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0)),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(child: StatCard(
                            label: 'Urgentes',
                            value: stats.urgent.toString(),
                            icon: Icons.warning_rounded,
                            color: AppTheme.kubikCoral,
                          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2, end: 0)),
                          const SizedBox(width: 12),
                          Expanded(child: StatCard(
                            label: 'Vencidas',
                            value: stats.overdue.toString(),
                            icon: Icons.timer_off_rounded,
                            color: Colors.deepOrange,
                          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Alarmas urgentes ───────────────────────────────────
              if (urgentTasks.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: '🚨 Alarmas Urgentes',
                    subtitle: '${urgentTasks.length} tarea(s) crítica(s)',
                    onSeeAll: () => context.go(AppRoutes.tasks),
                  ).animate().fadeIn(delay: 350.ms),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      child: TaskCard(
                        task: urgentTasks[i],
                        isUrgentStyle: true,
                        onTap: () => context.push(AppRoutes.taskDetail, extra: urgentTasks[i]),
                        onToggle: () => ref.read(taskNotifierProvider.notifier).toggleCompletion(urgentTasks[i]),
                      ).animate().fadeIn(delay: Duration(milliseconds: 400 + i * 60)),
                    ),
                    childCount: urgentTasks.length,
                  ),
                ),
              ],

              // ── Tareas de hoy ──────────────────────────────────────
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: '📅 Hoy',
                  subtitle: todayTasks.isEmpty
                      ? 'Sin tareas para hoy'
                      : '${todayTasks.length} tarea(s)',
                  onSeeAll: () => context.go(AppRoutes.calendar),
                ).animate().fadeIn(delay: 400.ms),
              ),

              if (todayTasks.isEmpty)
                SliverToBoxAdapter(
                  child: _EmptySection(
                    message: '¡No tienes tareas para hoy!',
                    icon: Icons.celebration_rounded,
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      child: TaskCard(
                        task: todayTasks[i],
                        onTap: () => context.push(AppRoutes.taskDetail, extra: todayTasks[i]),
                        onToggle: () => ref.read(taskNotifierProvider.notifier).toggleCompletion(todayTasks[i]),
                      ).animate().fadeIn(delay: Duration(milliseconds: 450 + i * 60)),
                    ),
                    childCount: todayTasks.length,
                  ),
                ),

              // ── Próximas tareas ────────────────────────────────────
              if (upcomingTasks.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: '🕐 Próximas',
                    subtitle: 'Las que vienen',
                    onSeeAll: () => context.go(AppRoutes.tasks),
                  ).animate().fadeIn(delay: 500.ms),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      child: TaskCard(
                        task: upcomingTasks[i],
                        onTap: () => context.push(AppRoutes.taskDetail, extra: upcomingTasks[i]),
                        onToggle: () => ref.read(taskNotifierProvider.notifier).toggleCompletion(upcomingTasks[i]),
                      ).animate().fadeIn(delay: Duration(milliseconds: 550 + i * 60)),
                    ),
                    childCount: upcomingTasks.length,
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.taskForm),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva Tarea', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
      ).animate().scale(delay: 600.ms, curve: Curves.elasticOut),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return '☀️ Buenos días';
    if (hour < 19) return '🌤 Buenas tardes';
    return '🌙 Buenas noches';
  }
}

// ─── Widget de progreso circular ─────────────────────────────────────────────
class _ProgressCard extends StatelessWidget {
  final TaskStats stats;
  final bool isDark;

  const _ProgressCard({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.kubikCoral, AppTheme.kubikBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kubikBlue.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Círculo de progreso
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: stats.completionRate,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  color: Colors.white,
                  strokeWidth: 6,
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  '${(stats.completionRate * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w700, fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Progreso general',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Poppins'),
                ),
                const SizedBox(height: 4),
                Text('${stats.completed} de ${stats.total} tareas',
                  style: const TextStyle(
                    color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.w700, fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                if (stats.dueToday > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${stats.dueToday} para hoy',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Encabezado de sección ────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, required this.subtitle, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text('Ver todo', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

// ─── Sección vacía ────────────────────────────────────────────────────────────
class _EmptySection extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptySection({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.kubikBlue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.kubikBlue.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.kubikBlue, size: 28),
            const SizedBox(width: 12),
            Text(message, style: TextStyle(
              color: AppTheme.kubikBlue, fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            )),
          ],
        ),
      ),
    );
  }
}
