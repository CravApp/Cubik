// lib/features/notifications/data/notification_service.dart
//
// ╔══════════════════════════════════════════════════════════════════════╗
// ║          SERVICIO DE NOTIFICACIONES Y ALARMAS                       ║
// ║  Responsabilidad: Gestionar todas las notificaciones locales        ║
// ║  y alarmas de la app usando flutter_local_notifications.            ║
// ║                                                                      ║
// ║  ARQUITECTURA DE ALARMAS:                                           ║
// ║  ┌─────────────────────────────────────────────────────────┐        ║
// ║  │  Tarea Normal → Notificación programada (1 disparo)     │        ║
// ║  │  Tarea Urgente → Canal HIGH IMPORTANCE + sonido         │        ║
// ║  │                  continuo hasta descarte manual          │        ║
// ║  └─────────────────────────────────────────────────────────┘        ║
// ╚══════════════════════════════════════════════════════════════════════╝

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

// ─── IDs de canales de notificación Android ────────────────────────────────────
// IMPORTANTE: Estos IDs deben coincidir con los declarados en AndroidManifest.xml
const String kTaskReminderChannelId = 'task_reminder_channel';
const String kUrgentAlarmChannelId = 'urgent_alarm_channel';
const String kGeneralChannelId = 'general_channel';

class NotificationService {
  // ── Instancia singleton ──────────────────────────────────────────
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // ────────────────────────────────────────────────────────────────────────────
  // INICIALIZACIÓN
  // Debe llamarse en main() antes de runApp()
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_isInitialized) return;

    // Inicializa las zonas horarias (requerido para notificaciones programadas)
    tz.initializeTimeZones();

    // ─── Configuración para Android ─────────────────────────────────
    // 'app_icon' debe existir en android/app/src/main/res/drawable/
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // ─── Configuración para iOS/macOS ───────────────────────────────
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      // Callback cuando el usuario toca la notificación mientras la app está activa
      onDidReceiveNotificationResponse: _onNotificationResponse,
      // Callback para notificaciones de segundo plano
      onDidReceiveBackgroundNotificationResponse: _backgroundNotificationHandler,
    );

    // ─── Crear canales de notificación (SOLO Android 8+) ────────────
    // CRÍTICO: Los canales deben crearse ANTES de enviar cualquier notificación.
    // Una vez creado, el usuario puede cambiar la configuración del canal
    // desde los ajustes del sistema; la app no puede sobreescribirlo.
    await _createAndroidChannels();

    // ─── Solicitar permisos en Android 13+ (API 33+) ────────────────
    // A partir de Android 13, se requiere permiso explícito para notificaciones.
    // Sin este permiso, las notificaciones no se mostrarán.
    await _requestPermissions();

    _isInitialized = true;
    debugPrint('✅ NotificationService inicializado correctamente');
  }

  // ────────────────────────────────────────────────────────────────────────────
  // CREAR CANALES ANDROID
  // Cada canal tiene su propio nivel de importancia y configuración de audio
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> _createAndroidChannels() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Canal 1: Recordatorios normales (importancia media)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        kTaskReminderChannelId,
        'Recordatorios de Tareas',
        description: 'Notificaciones de vencimiento próximo de tareas',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    // Canal 2: Alarmas urgentes (importancia máxima, sonido de alarma)
    // CRÍTICO: importance.max + fullScreenIntent = alarma que aparece sobre
    // cualquier pantalla, incluso con el dispositivo bloqueado.
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        kUrgentAlarmChannelId,
        'Alarmas Urgentes',
        description: 'Alarmas para tareas marcadas como urgentes',
        importance: Importance.max, // Máxima prioridad
        playSound: true,
        enableLights: true,
        ledColor: const Color(0xFFFF0000), // LED rojo en dispositivos compatibles
        enableVibration: true,
      ),
    );

    // Canal 3: Notificaciones generales de la app
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        kGeneralChannelId,
        'General',
        description: 'Notificaciones generales de Kubik',
        importance: Importance.defaultImportance,
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // SOLICITAR PERMISOS
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> _requestPermissions() async {
    // Solicitar permiso en iOS
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Solicitar permiso en Android 13+ (API 33+)
    // IMPORTANTE: En Android 12 y anteriores este método no hace nada
    // ya que no se requiere permiso explícito.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // PERMISO DE ALARMA EXACTA (Android 12+, API 31+)
    // Sin este permiso, las alarmas se ejecutan con retraso de hasta 10 minutos.
    // El usuario debe ir a Ajustes → Aplicaciones → Kubik → Alarmas y recordatorios
    // y activar "Permitir alarmas y recordatorios".
    // Nota: Solicitar este permiso automáticamente puede ser rechazado por Google Play
    // si no justificas su uso en el formulario de la store.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // PROGRAMAR RECORDATORIO NORMAL
  // Muestra una notificación N minutos antes del vencimiento de la tarea
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> scheduleTaskReminder({
    required int notificationId,
    required String taskTitle,
    required String taskDescription,
    required DateTime dueDate,
    required int minutesBefore,
  }) async {
    // Calcula el momento en que se debe disparar la notificación
    final scheduledTime = dueDate.subtract(Duration(minutes: minutesBefore));

    // Si el tiempo ya pasó, no programamos la notificación
    if (scheduledTime.isBefore(DateTime.now())) {
      debugPrint('⚠️ No se programó notificación: el tiempo ya pasó');
      return;
    }

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    // Detalles específicos de Android para este recordatorio
    final androidDetails = AndroidNotificationDetails(
      kTaskReminderChannelId,
      'Recordatorios de Tareas',
      channelDescription: 'Recordatorio de tarea próxima a vencer',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF6C63FF),
      styleInformation: const BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      notificationId,
      '⏰ Tarea próxima: $taskTitle',
      taskDescription.isNotEmpty
          ? taskDescription
          : 'Vence en $minutesBefore minutos',
      tzScheduledTime,
      notificationDetails,
      // androidScheduleMode.exactAllowWhileIdle: alarma exacta incluso
      // cuando el dispositivo está en modo Doze (ahorro de batería).
      // Requiere permiso USE_EXACT_ALARM o SCHEDULE_EXACT_ALARM en el manifest.
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint(
        '✅ Recordatorio programado para: $tzScheduledTime (tarea: $taskTitle)');
  }

  // ────────────────────────────────────────────────────────────────────────────
  // DISPARAR ALARMA URGENTE
  // Notificación persistente de alta prioridad con fullScreenIntent
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> showUrgentAlarm({
    required int notificationId,
    required String taskTitle,
    required String taskDescription,
    required DateTime dueDate,
  }) async {
    // Las alarmas urgentes también se pueden programar
    final scheduledTime = dueDate.subtract(const Duration(minutes: 5));
    final now = DateTime.now();
    final triggerTime =
        scheduledTime.isBefore(now) ? now.add(const Duration(seconds: 5)) : scheduledTime;

    final tzTriggerTime = tz.TZDateTime.from(triggerTime, tz.local);

    // CONFIGURACIÓN CRÍTICA DE ALARMA URGENTE:
    // - fullScreenIntent: true → abre la app encima de la pantalla de bloqueo
    // - ongoing: true → la notificación NO se puede deslizar para cerrar
    // - autoCancel: false → el usuario DEBE tocarla para descartarla
    // - category: NotificationCategory.alarm → el sistema la trata como alarma
    final androidDetails = AndroidNotificationDetails(
      kUrgentAlarmChannelId,
      'Alarmas Urgentes',
      channelDescription: '¡Tarea URGENTE venciendo!',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true, // Aparece sobre la pantalla de bloqueo
      ongoing: true,          // No se puede deslizar
      autoCancel: false,       // No se cancela al tocar
      enableLights: true,
      color: const Color(0xFFFF5252), // Rojo urgente
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        '¡URGENTE! ${taskDescription.isNotEmpty ? taskDescription : 'Esta tarea vence ahora'}',
        htmlFormatBigText: false,
        contentTitle: '🚨 $taskTitle',
        htmlFormatContentTitle: false,
      ),
      // Acciones en la notificación (el usuario puede descartarla desde aquí)
      actions: [
        const AndroidNotificationAction(
          'dismiss_alarm',
          '✓ Descartar',
          cancelNotification: true,
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'view_task',
          '👁 Ver Tarea',
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical, // Modo crítico en iOS
    );

    await _plugin.zonedSchedule(
      notificationId,
      '🚨 ¡URGENTE! $taskTitle',
      '¡Esta tarea vence ahora! Toca para descartarla.',
      tzTriggerTime,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('🚨 Alarma urgente programada para: $tzTriggerTime');
  }

  // ────────────────────────────────────────────────────────────────────────────
  // CANCELAR NOTIFICACIÓN
  // Cancela una notificación específica por su ID
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> cancelNotification(int notificationId) async {
    await _plugin.cancel(notificationId);
    debugPrint('🗑 Notificación #$notificationId cancelada');
  }

  /// Cancela TODAS las notificaciones programadas de la app
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
    debugPrint('🗑 Todas las notificaciones canceladas');
  }

  // ────────────────────────────────────────────────────────────────────────────
  // NOTIFICACIÓN INMEDIATA (para pruebas o feedback al usuario)
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      kGeneralChannelId,
      'General',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  // ─── Callbacks ───────────────────────────────────────────────────

  /// Callback ejecutado cuando el usuario toca una notificación
  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('🔔 Notificación tocada: ${response.payload}');
    // Aquí puedes navegar a la tarea específica usando el payload (taskId)
  }
}

// Callback para notificaciones en segundo plano (top-level function, obligatorio)
@pragma('vm:entry-point')
void _backgroundNotificationHandler(NotificationResponse response) {
  debugPrint('🔔 BG Notificación: ${response.payload}');
}

// ────────────────────────────────────────────────────────────────────────────
// HELPER: Genera un ID de notificación único a partir del ID de la tarea
// Los IDs deben ser enteros de 32 bits, así que hasheamos el UUID.
// ────────────────────────────────────────────────────────────────────────────
int generateNotificationId(String taskId) {
  return taskId.hashCode.abs() % 2147483647;
}
