// lib/features/settings/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../tasks/presentation/providers/task_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Apariencia ────────────────────────────────────────
          _SectionTitle('Apariencia'),
          _SettingsTile(
            icon: isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            title: 'Modo oscuro',
            trailing: Switch.adaptive(
              value: isDarkMode,
              activeThumbColor: AppTheme.kubikBlue,
              onChanged: (v) => ref.read(themeModeProvider.notifier).state = v,
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 20),

          // ── Notificaciones ────────────────────────────────────
          _SectionTitle('Notificaciones'),
          _SettingsTile(
            icon: Icons.notifications_rounded,
            title: 'Activar notificaciones',
            trailing: Switch.adaptive(
              value: true,
              activeThumbColor: AppTheme.kubikBlue,
              onChanged: (_) {},
            ),
          ).animate().fadeIn(delay: 150.ms),

          _SettingsTile(
            icon: Icons.alarm_rounded,
            title: 'Alarmas urgentes',
            subtitle: 'Sonido persistente para tareas urgentes',
            trailing: Switch.adaptive(
              value: true,
              activeThumbColor: AppTheme.kubikBlue,
              onChanged: (_) {},
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 20),

          // ── Permisos requeridos ───────────────────────────────
          _SectionTitle('Permisos (Android)'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.kubikBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.kubikBlue.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PermissionRow(
                  icon: Icons.notifications_rounded,
                  label: 'Notificaciones',
                  description: 'Necesario para recordatorios (Android 13+)',
                  status: true,
                ),
                const Divider(height: 16),
                _PermissionRow(
                  icon: Icons.alarm_rounded,
                  label: 'Alarmas exactas',
                  description: 'Ajustes → Apps → Kubik → Alarmas y recordatorios',
                  status: true,
                ),
                const Divider(height: 16),
                _PermissionRow(
                  icon: Icons.battery_full_rounded,
                  label: 'Sin restricción batería',
                  description: 'Para notificaciones en segundo plano',
                  status: true,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 250.ms),

          const SizedBox(height: 20),

          // ── Datos ─────────────────────────────────────────────
          _SectionTitle('Datos'),
          _SettingsTile(
            icon: Icons.backup_rounded,
            title: 'Exportar datos',
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: () {},
          ).animate().fadeIn(delay: 300.ms),

          _SettingsTile(
            icon: Icons.delete_sweep_rounded,
            title: 'Limpiar tareas completadas',
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: () => _showClearDialog(context),
          ).animate().fadeIn(delay: 350.ms),

          const SizedBox(height: 20),

          // ── Versión ───────────────────────────────────────────
          Center(
            child: Text('Kubik v1.0.0 • Flutter 3.35',
              style: TextStyle(
                fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade400,
              ),
            ),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context) => showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('¿Limpiar completadas?', style: TextStyle(fontFamily: 'Poppins')),
      content: const Text('Se eliminarán todas las tareas marcadas como completadas.', style: TextStyle(fontFamily: 'Poppins')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kubikCoral),
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Limpiar'),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: TextStyle(
        fontFamily: 'Poppins', fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppTheme.kubikBlue,
        letterSpacing: 0.8,
      )),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon, required this.title,
    this.subtitle, this.trailing, this.onTap,
  });

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
        title: Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11)) : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool status;

  const _PermissionRow({
    required this.icon, required this.label,
    required this.description, required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.kubikBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600)),
              Text(description, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: status ? AppTheme.accentGreen.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            status ? 'Activo' : 'Pendiente',
            style: TextStyle(
              color: status ? AppTheme.accentGreen : Colors.orange,
              fontSize: 9, fontWeight: FontWeight.w700, fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }
}
