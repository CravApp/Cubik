// lib/features/tasks/presentation/screens/task_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/task_providers.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  final TaskEntity? existingTask;
  const TaskFormScreen({super.key, this.existingTask});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late DateTime _dueDate;
  late TaskPriority _priority;
  late bool _isUrgent;
  late bool _hasReminder;
  late int _reminderMins;
  bool _saving = false;

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    _titleCtrl = TextEditingController(text: task?.title ?? '');
    _descCtrl = TextEditingController(text: task?.description ?? '');
    _dueDate = task?.dueDate ?? DateTime.now().add(const Duration(hours: 1));
    _priority = task?.priority ?? TaskPriority.medium;
    _isUrgent = task?.isUrgent ?? false;
    _hasReminder = task?.hasReminder ?? true;
    _reminderMins = task?.reminderMinutesBefore ?? 30;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppTheme.kubikBlue),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppTheme.kubikBlue),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    setState(() {
      _dueDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final notifier = ref.read(taskNotifierProvider.notifier);

    if (_isEditing) {
      final updated = widget.existingTask!.copyWith(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        dueDate: _dueDate,
        priority: _priority,
        isUrgent: _isUrgent,
        hasReminder: _hasReminder,
        reminderMinutesBefore: _reminderMins,
      );
      await notifier.updateTask(updated);
    } else {
      await notifier.addTask(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        dueDate: _dueDate,
        priority: _priority,
        isUrgent: _isUrgent,
        hasReminder: _hasReminder,
        reminderMinutesBefore: _reminderMins,
      );
    }

    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? '✅ Tarea actualizada' : '✅ Tarea creada'),
          backgroundColor: AppTheme.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Tarea' : 'Nueva Tarea'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.kubikBlue))
                : const Text('Guardar', style: TextStyle(
                    fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppTheme.kubikBlue)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Título
            _buildFieldLabel('Título *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(hintText: 'Nombre de la tarea'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'El título es obligatorio' : null,
              textCapitalization: TextCapitalization.sentences,
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 20),

            // Descripción
            _buildFieldLabel('Descripción'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Detalles de la tarea (opcional)'),
              textCapitalization: TextCapitalization.sentences,
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 20),

            // Fecha y hora
            _buildFieldLabel('Fecha y hora de vencimiento *'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDateTime,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : const Color(0xFFF0F0FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: AppTheme.kubikBlue, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy  •  HH:mm', 'es_ES').format(_dueDate),
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.kubikBlue),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 20),

            // Prioridad
            _buildFieldLabel('Prioridad'),
            const SizedBox(height: 8),
            Row(
              children: TaskPriority.values.map((p) {
                final isSelected = _priority == p;
                final color = _priorityColor(p);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _priority = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withValues(alpha: 0.15) : (isDark ? AppTheme.cardDark : Colors.white),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? color : (isDark ? AppTheme.dividerDark : AppTheme.dividerLight),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(height: 4),
                          Text(_priorityLabel(p), style: TextStyle(
                            fontSize: 11, fontFamily: 'Poppins',
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                            color: isSelected ? color : Colors.grey,
                          )),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(delay: 250.ms),

            const SizedBox(height: 20),

            // Opciones de recordatorio
            _buildFieldLabel('Recordatorios y Alarmas'),
            const SizedBox(height: 12),

            // Toggle: activar recordatorio
            _ToggleTile(
              icon: Icons.notifications_rounded,
              title: 'Activar recordatorio',
              subtitle: 'Recibir notificación antes de la fecha límite',
              value: _hasReminder,
              onChanged: (v) => setState(() => _hasReminder = v),
            ).animate().fadeIn(delay: 300.ms),

            // Tiempo antes del recordatorio
            if (_hasReminder) ...[
              const SizedBox(height: 12),
              _buildFieldLabel('Recordar con anticipación'),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _reminderMins,
                decoration: const InputDecoration(),
                items: [5, 10, 15, 30, 60, 120, 1440].map((mins) {
                  final label = mins < 60 ? '$mins minutos'
                      : mins == 60 ? '1 hora'
                      : mins == 120 ? '2 horas'
                      : '1 día antes';
                  return DropdownMenuItem(value: mins, child: Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)));
                }).toList(),
                onChanged: (v) => setState(() => _reminderMins = v!),
              ).animate().fadeIn(delay: 350.ms),
            ],

            const SizedBox(height: 12),

            // Toggle: tarea urgente
            _ToggleTile(
              icon: Icons.warning_rounded,
              title: '🚨 Marcar como URGENTE',
              subtitle: 'Activa alarma persistente que no se puede deslizar',
              value: _isUrgent,
              color: AppTheme.kubikCoral,
              onChanged: (v) => setState(() => _isUrgent = v),
            ).animate().fadeIn(delay: 400.ms),

            if (_isUrgent)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.kubikCoral.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.kubikCoral.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppTheme.kubikCoral, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'La alarma urgente aparecerá sobre la pantalla de bloqueo y NO se puede deslizar para cerrar.',
                        style: TextStyle(
                          fontFamily: 'Poppins', fontSize: 11,
                          color: AppTheme.kubikCoral,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 450.ms),

            const SizedBox(height: 48),

            // Botón guardar principal
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(_isEditing ? Icons.save_rounded : Icons.add_task_rounded),
                label: Text(_isEditing ? 'Actualizar Tarea' : 'Crear Tarea'),
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(text, style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w600,
      color: Color(0xFF3D3D5C), fontFamily: 'Poppins',
    ));
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.low: return AppTheme.priorityLow;
      case TaskPriority.medium: return AppTheme.priorityMedium;
      case TaskPriority.high: return AppTheme.priorityHigh;
    }
  }

  String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.low: return 'Baja';
      case TaskPriority.medium: return 'Media';
      case TaskPriority.high: return 'Alta';
    }
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? color;

  const _ToggleTile({
    required this.icon, required this.title,
    required this.subtitle, required this.value,
    required this.onChanged, this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = color ?? AppTheme.kubikBlue;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? c.withValues(alpha: 0.3) : (isDark ? AppTheme.dividerDark : AppTheme.dividerLight),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: c, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                )),
                Text(subtitle, style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 10,
                  color: isDark ? const Color(0xFF8080A0) : Colors.grey.shade500,
                )),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: c,
          ),
        ],
      ),
    );
  }
}
