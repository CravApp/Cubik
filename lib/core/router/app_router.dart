// lib/core/router/app_router.dart
//
// ╔══════════════════════════════════════════════════════════════╗
// ║          ENRUTADOR DECLARATIVO – GoRouter                   ║
// ║  Define todas las rutas de navegación de la aplicación.     ║
// ╚══════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/tasks/presentation/screens/dashboard_screen.dart';
import '../../features/tasks/presentation/screens/task_list_screen.dart';
import '../../features/tasks/presentation/screens/task_form_screen.dart';
import '../../features/tasks/presentation/screens/task_detail_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/tasks/domain/entities/task_entity.dart';
import '../widgets/main_shell.dart';

// ─── Rutas con nombre ──────────────────────────────────────────────────────
abstract class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const tasks = '/tasks';
  static const calendar = '/calendar';
  static const profile = '/profile';
  static const settings = '/settings';
  static const taskForm = '/task/form';
  static const taskDetail = '/task/detail';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: false,
  routes: [
    // ── Splash ───────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),

    // ── Login ─────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.login,
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const LoginScreen(),
        transitionsBuilder: _fadeTransition,
      ),
    ),

    // ── Shell con Bottom Navigation ───────────────────────────────────
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.tasks,
          builder: (context, state) => const TaskListScreen(),
        ),
        GoRoute(
          path: AppRoutes.calendar,
          builder: (context, state) => const CalendarScreen(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),

    // ── Formulario de tarea (fuera del shell para pantalla completa) ──
    GoRoute(
      path: AppRoutes.taskForm,
      pageBuilder: (context, state) {
        final task = state.extra as TaskEntity?;
        return CustomTransitionPage(
          child: TaskFormScreen(existingTask: task),
          transitionsBuilder: _slideUpTransition,
        );
      },
    ),

    // ── Detalle de tarea ─────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.taskDetail,
      pageBuilder: (context, state) {
        final task = state.extra as TaskEntity;
        return CustomTransitionPage(
          child: TaskDetailScreen(task: task),
          transitionsBuilder: _slideTransition,
        );
      },
    ),
  ],
);

// ─── Transiciones personalizadas ─────────────────────────────────────────────
Widget _fadeTransition(
    BuildContext context, Animation<double> animation,
    Animation<double> secondary, Widget child) {
  return FadeTransition(opacity: animation, child: child);
}

Widget _slideTransition(
    BuildContext context, Animation<double> animation,
    Animation<double> secondary, Widget child) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
    child: child,
  );
}

Widget _slideUpTransition(
    BuildContext context, Animation<double> animation,
    Animation<double> secondary, Widget child) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
    child: child,
  );
}
