// lib/core/widgets/main_shell.dart
// Shell con Bottom Navigation Bar persistente
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith(AppRoutes.calendar)) return 1;
    if (location.startsWith(AppRoutes.tasks)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    if (location.startsWith(AppRoutes.settings)) return 4;
    return 0; // home
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_rounded, label: 'Inicio', index: 0, current: currentIndex, onTap: () => context.go(AppRoutes.home)),
                _NavItem(icon: Icons.calendar_month_rounded, label: 'Calendario', index: 1, current: currentIndex, onTap: () => context.go(AppRoutes.calendar)),
                _NavItem(icon: Icons.task_alt_rounded, label: 'Tareas', index: 2, current: currentIndex, onTap: () => context.go(AppRoutes.tasks)),
                _NavItem(icon: Icons.person_rounded, label: 'Perfil', index: 3, current: currentIndex, onTap: () => context.go(AppRoutes.profile)),
                _NavItem(icon: Icons.settings_rounded, label: 'Ajustes', index: 4, current: currentIndex, onTap: () => context.go(AppRoutes.settings)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon, required this.label,
    required this.index, required this.current, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == current;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12, vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.kubikBlue.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
              color: isSelected ? AppTheme.kubikBlue : const Color(0xFFB0B0C0),
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(label,
                style: TextStyle(
                  color: AppTheme.kubikBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
