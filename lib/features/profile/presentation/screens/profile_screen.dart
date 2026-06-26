// lib/features/profile/presentation/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../tasks/presentation/providers/task_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(taskStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header con gradiente ────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.kubikCoral, AppTheme.kubikBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    // Avatar con logo Kubik
                    Container(
                      width: 84, height: 84,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 3),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        'assets/images/kubik_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                    const SizedBox(height: 12),

                    const Text('PEPITO', style: TextStyle(
                      color: Colors.white, fontSize: 22,
                      fontWeight: FontWeight.w700, fontFamily: 'Poppins',
                    )).animate().fadeIn(delay: 200.ms),

                    Text('pepito@kubik.app', style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7), fontSize: 13,
                      fontFamily: 'Poppins',
                    )).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Estadísticas ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _StatBox(label: 'Total', value: stats.total.toString(), color: AppTheme.kubikBlue),
                    _StatBox(label: 'Hechas', value: stats.completed.toString(), color: AppTheme.accentGreen),
                    _StatBox(label: 'Urgentes', value: stats.urgent.toString(), color: AppTheme.kubikCoral),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 24),

              // ── Opciones ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Configuración', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _OptionTile(
                      icon: Icons.settings_rounded,
                      label: 'Ajustes de la app',
                      onTap: () => context.go(AppRoutes.settings),
                    ).animate().fadeIn(delay: 450.ms),
                    _OptionTile(
                      icon: Icons.notifications_rounded,
                      label: 'Notificaciones',
                      onTap: () {},
                    ).animate().fadeIn(delay: 500.ms),
                    _OptionTile(
                      icon: Icons.language_rounded,
                      label: 'Idioma',
                      trailing: const Text('Español', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey)),
                      onTap: () {},
                    ).animate().fadeIn(delay: 550.ms),
                    _OptionTile(
                      icon: Icons.info_outline_rounded,
                      label: 'Acerca de Kubik',
                      onTap: () {},
                    ).animate().fadeIn(delay: 600.ms),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Cerrar sesión ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.kubikCoral.withValues(alpha: 0.1),
                      foregroundColor: AppTheme.kubikCoral,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        side: BorderSide(color: AppTheme.kubikCoral),
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Cerrar Sesión', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                    onPressed: () => context.go(AppRoutes.login),
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
          ),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w700,
              color: color, fontFamily: 'Poppins',
            )),
            Text(label, style: TextStyle(
              fontSize: 10, fontFamily: 'Poppins',
              color: isDark ? const Color(0xFF8080A0) : Colors.grey.shade500,
            )),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  const _OptionTile({required this.icon, required this.label, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight),
      ),
      child: ListTile(
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppTheme.kubikBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.kubikBlue, size: 18),
        ),
        title: Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500)),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
        onTap: onTap,
      ),
    );
  }
}
