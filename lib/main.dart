// lib/main.dart
//
// ╔══════════════════════════════════════════════════════════════════════╗
// ║                    KUBIK TASKS – Entry Point                        ║
// ║                                                                      ║
// ║  Orden de inicialización:                                            ║
// ║  1. Flutter bindings                                                 ║
// ║  2. Hive (base de datos local)                                       ║
// ║  3. NotificationService (canales Android, permisos)                 ║
// ║  4. intl (localización en español)                                   ║
// ║  5. runApp con ProviderScope (Riverpod)                              ║
// ╚══════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/notifications/data/notification_service.dart';
import 'features/tasks/data/datasources/task_local_datasource.dart';
import 'features/tasks/presentation/providers/task_providers.dart';

Future<void> main() async {
  // ── 1. Bindings de Flutter ────────────────────────────────────────
  WidgetsFlutterBinding.ensureInitialized();

  // ── 2. Orientación fija en portrait (app móvil) ───────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── 3. Configurar barra de estado transparente ────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // ── 4. Inicializar Hive (base de datos local) ─────────────────────
  final taskDataSource = TaskLocalDataSource();
  await taskDataSource.init();

  // ── 5. Inicializar servicio de notificaciones ─────────────────────
  // IMPORTANTE: Debe inicializarse antes de runApp() para que los
  // canales de Android estén listos cuando la app arranque.
  await NotificationService().init();

  // ── 6. Inicializar localización en español ────────────────────────
  await initializeDateFormatting('es_ES', null);

  // ── 7. Arrancar la aplicación con Riverpod ────────────────────────
  runApp(
    ProviderScope(
      // Sobreescribe el datasource con la instancia ya inicializada
      overrides: [
        taskDataSourceProvider.overrideWithValue(taskDataSource),
      ],
      child: const KubikTasksApp(),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET RAÍZ DE LA APLICACIÓN
// ─────────────────────────────────────────────────────────────────────────────
class KubikTasksApp extends ConsumerWidget {
  const KubikTasksApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escucha el provider de tema para cambio dinámico claro/oscuro
    final isDarkMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      // ── Metadatos de la app ────────────────────────────────────
      title: 'Kubik',
      debugShowCheckedModeBanner: false,

      // ── Tema ───────────────────────────────────────────────────
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // ── Localización ───────────────────────────────────────────
      locale: const Locale('es', 'ES'),

      // ── Enrutamiento (GoRouter) ────────────────────────────────
      routerConfig: appRouter,
    );
  }
}
