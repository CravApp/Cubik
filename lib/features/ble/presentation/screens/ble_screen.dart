// lib/features/ble/presentation/screens/ble_screen.dart
//
// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  PANTALLA BLE – Gestión de conexión ESP32                                ║
// ║                                                                           ║
// ║  Secciones:                                                               ║
// ║   1. Panel de estado de conexión (con ícono animado y datos del device)  ║
// ║   2. Escaneo de dispositivos (lista interactiva con señal y botón Conectar)║
// ║   3. Panel del dispositivo conectado: batería + envío de tareas          ║
// ║   4. Log de comunicación en tiempo real                                   ║
// ╚══════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../domain/entities/ble_device_entity.dart';
import '../providers/ble_providers.dart';

class BleScreen extends ConsumerStatefulWidget {
  const BleScreen({super.key});

  @override
  ConsumerState<BleScreen> createState() => _BleScreenState();
}

class _BleScreenState extends ConsumerState<BleScreen> {
  final List<String> _log = [];
  bool _showAllDevices = false;

  void _addLog(String msg) {
    final time = DateFormat('HH:mm:ss').format(DateTime.now());
    setState(() {
      _log.insert(0, '[$time] $msg');
      if (_log.length > 50) _log.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    final connState    = ref.watch(bleConnectionStateProvider);
    final battery      = ref.watch(bleBatteryProvider);
    final devices      = ref.watch(bleScannedDevicesProvider);
    final connDevice   = ref.watch(bleConnectedDeviceProvider);
    ref.watch(bleAlarmAcknowledgedProvider); // solo para escuchar cambios
    final lastSync     = ref.watch(bleLastSyncProvider);
    final mtu          = ref.watch(bleMtuProvider);
    final isConnected  = connState.isConnected;
    final isScanning   = connState.isScanning;
    final isDark       = Theme.of(context).brightness == Brightness.dark;

    // Escuchar confirmación de alarma del ESP32
    ref.listen(bleAlarmAcknowledgedProvider, (_, ack) {
      if (ack) {
        _addLog('✅ ESP32 confirmó: tarea recibida y procesada (ALARM_OK)');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Text('ESP32 confirmó la tarea', style: TextStyle(fontFamily: 'Poppins')),
              ]),
              backgroundColor: AppTheme.accentGreen,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    });

    final visibleDevices = _showAllDevices ? devices : devices.take(5).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
      appBar: AppBar(
        title: const Text('Conexión ESP32'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (isConnected)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton.icon(
                icon: const Icon(Icons.bluetooth_disabled_rounded, size: 16),
                label: const Text('Desconectar'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.kubikCoral),
                onPressed: () {
                  ref.read(bleNotifierProvider.notifier).disconnect();
                  _addLog('🔌 Desconectado por el usuario');
                },
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        children: [
          // ════════════════════════════════════════════════════════
          // SECCIÓN 1: Estado de conexión
          // ════════════════════════════════════════════════════════
          _ConnectionStatusCard(
            connState: connState,
            connDevice: connDevice,
            battery: battery,
            mtu: mtu,
            lastSync: lastSync,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

          const SizedBox(height: 16),

          // ════════════════════════════════════════════════════════
          // SECCIÓN 2: Escaneo de dispositivos
          // ════════════════════════════════════════════════════════
          if (!isConnected) ...[
            _SectionTitle(
              title: 'Dispositivos BLE cercanos',
              trailing: isScanning
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.kubikBlue,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 10),

            // Botón de escaneo
            ElevatedButton.icon(
              icon: Icon(isScanning ? Icons.stop_rounded : Icons.radar_rounded),
              label: Text(isScanning ? 'Detener escaneo' : 'Buscar ESP32 Kubik'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isScanning ? AppTheme.kubikCoral : AppTheme.kubikBlue,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                if (isScanning) {
                  ref.read(bleNotifierProvider.notifier).stopScan();
                  _addLog('🔍 Escaneo detenido');
                } else {
                  ref.read(bleNotifierProvider.notifier).startScan();
                  _addLog('🔍 Iniciando escaneo BLE...');
                }
              },
            ),

            const SizedBox(height: 12),

            // Lista de dispositivos
            if (devices.isEmpty && !isScanning)
              _EmptyDevicesHint()
            else
              ...visibleDevices.map((device) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DeviceListTile(
                  device: device,
                  onConnect: () async {
                    _addLog('🔗 Conectando con ${device.name} (${device.id})...');
                    final ok = await ref
                        .read(bleNotifierProvider.notifier)
                        .connect(device.id);
                    if (ok) {
                      _addLog('✅ Conectado a ${device.name} | MTU=${ref.read(bleMtuProvider)}B');
                    } else {
                      _addLog('❌ Error al conectar con ${device.name}');
                    }
                  },
                ),
              )),

            if (devices.length > 5)
              TextButton(
                onPressed: () => setState(() => _showAllDevices = !_showAllDevices),
                child: Text(
                  _showAllDevices
                      ? 'Mostrar menos'
                      : 'Ver ${devices.length - 5} más...',
                ),
              ),
          ],

          // ════════════════════════════════════════════════════════
          // SECCIÓN 3: Panel del dispositivo conectado
          // ════════════════════════════════════════════════════════
          if (isConnected) ...[
            _SectionTitle(title: 'Enviar tarea al ESP32'),
            const SizedBox(height: 10),
            _SendTaskPanel(
              onSend: (task) async {
                _addLog('📤 Enviando: "${task.title}"...');
                final result = await ref
                    .read(bleNotifierProvider.notifier)
                    .sendTask(task);
                if (result.success) {
                  _addLog('✅ Enviado: ${result.chunksWritten} chunk(s), '
                      '${result.totalBytes}B totales');
                } else {
                  _addLog('❌ Error: ${result.error}');
                }
              },
            ),
            const SizedBox(height: 16),

            // Batería y MTU info
            _DeviceInfoPanel(battery: battery, mtu: mtu, lastSync: lastSync),
          ],

          const SizedBox(height: 20),

          // ════════════════════════════════════════════════════════
          // SECCIÓN 4: Log de comunicación
          // ════════════════════════════════════════════════════════
          if (_log.isNotEmpty) ...[
            Row(
              children: [
                const _SectionTitle(title: 'Log de comunicación'),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _log.clear()),
                  child: Text('Limpiar', style: TextStyle(
                    fontSize: 11, color: AppTheme.kubikCoral, fontFamily: 'Poppins',
                  )),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D0C1A) : const Color(0xFF1A1929),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                reverse: false,
                shrinkWrap: true,
                itemCount: _log.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: Text(
                    _log[i],
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 10,
                      color: Color(0xFF9EFFD0),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Card: estado de conexión ─────────────────────────────────────────────
class _ConnectionStatusCard extends StatelessWidget {
  final BleConnectionState connState;
  final BleDeviceEntity?   connDevice;
  final int?               battery;
  final int                mtu;
  final DateTime?          lastSync;

  const _ConnectionStatusCard({
    required this.connState,
    required this.connDevice,
    required this.battery,
    required this.mtu,
    required this.lastSync,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = connState.isConnected;
    final color = isConnected ? AppTheme.kubikBlue : AppTheme.kubikCoral;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isConnected
              ? [AppTheme.kubikBlue, AppTheme.kubikBlueDark]
              : [AppTheme.kubikCoral.withValues(alpha: 0.15),
                 AppTheme.kubikCoral.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Ícono animado
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isConnected ? 0.2 : 0.0),
              shape: BoxShape.circle,
              border: Border.all(
                color: isConnected ? Colors.white.withValues(alpha: 0.4) : color.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Icon(
              connState.isScanning
                  ? Icons.bluetooth_searching_rounded
                  : isConnected
                      ? Icons.bluetooth_connected_rounded
                      : Icons.bluetooth_disabled_rounded,
              size: 28,
              color: isConnected ? Colors.white : color,
            ),
          )
          .animate(
            onPlay: (c) => connState.isScanning ? c.repeat() : null,
          )
          .then()
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.1, 1.1),
            duration: 800.ms,
          )
          .then()
          .scale(
            begin: const Offset(1.1, 1.1),
            end: const Offset(1.0, 1.0),
            duration: 800.ms,
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connState.label,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isConnected ? Colors.white : color,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (connDevice != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    connDevice!.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: isConnected
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppTheme.kubikDarkMid,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    connDevice!.id,
                    style: TextStyle(
                      fontSize: 9,
                      color: isConnected
                          ? Colors.white.withValues(alpha: 0.5)
                          : const Color(0xFFAAAAAA),
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
                if (isConnected && battery != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.battery_full_rounded,
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.8)),
                    const SizedBox(width: 4),
                    Text('Batería ESP32: $battery%',
                        style: const TextStyle(
                          fontSize: 11, color: Colors.white70, fontFamily: 'Poppins',
                        )),
                    const SizedBox(width: 10),
                    Text('MTU: ${mtu}B',
                        style: const TextStyle(
                          fontSize: 11, color: Colors.white54, fontFamily: 'Poppins',
                        )),
                  ]),
                ],
                if (isConnected && lastSync != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Última sync: ${DateFormat('HH:mm:ss').format(lastSync!)}',
                    style: const TextStyle(
                      fontSize: 10, color: Colors.white54, fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tile de dispositivo BLE ──────────────────────────────────────────────
class _DeviceListTile extends StatelessWidget {
  final BleDeviceEntity device;
  final VoidCallback onConnect;

  const _DeviceListTile({required this.device, required this.onConnect});

  @override
  Widget build(BuildContext context) {
    final q     = device.signalQuality;
    final color = device.isKubikDevice ? AppTheme.kubikBlue : AppTheme.kubikDarkMid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: device.isKubikDevice
            ? AppTheme.kubikBlue.withValues(alpha: 0.07)
            : (isDark ? AppTheme.cardDark : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: device.isKubikDevice
              ? AppTheme.kubikBlue.withValues(alpha: 0.3)
              : AppTheme.dividerLight,
        ),
      ),
      child: Row(
        children: [
          // Ícono + badge Kubik
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.developer_board_rounded,
                color: color,
                size: 28,
              ),
              if (device.isKubikDevice)
                Positioned(
                  right: -4, bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppTheme.kubikBlue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('K', style: TextStyle(
                      color: Colors.white, fontSize: 7, fontWeight: FontWeight.w900,
                    )),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 12),

          // Nombre y datos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(device.name,
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: color, fontFamily: 'Poppins',
                      )),
                  if (device.isKubikDevice) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.kubikBlue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Kubik ESP32',
                          style: TextStyle(color: Colors.white, fontSize: 8,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(device.id,
                    style: const TextStyle(
                      fontSize: 10, color: Color(0xFFAAAAAA), fontFamily: 'Courier',
                    )),
                Row(children: [
                  _SignalBar(quality: q),
                  const SizedBox(width: 6),
                  Text('${device.rssi} dBm · ${device.signalLabel}',
                      style: const TextStyle(fontSize: 9, color: Color(0xFFAAAAAA),
                          fontFamily: 'Poppins')),
                ]),
              ],
            ),
          ),

          // Botón conectar
          ElevatedButton(
            onPressed: onConnect,
            style: ElevatedButton.styleFrom(
              backgroundColor: device.isKubikDevice ? AppTheme.kubikBlue : AppTheme.kubikDarkMid,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              textStyle: const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
            ),
            child: const Text('Conectar'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }
}

// ─── Barras de señal ──────────────────────────────────────────────────────
class _SignalBar extends StatelessWidget {
  final int quality; // 0–100
  const _SignalBar({required this.quality});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final active = quality >= (i + 1) * 25;
        return Container(
          width: 3,
          height: 4.0 + i * 3,
          margin: const EdgeInsets.only(right: 1),
          decoration: BoxDecoration(
            color: active ? AppTheme.accentGreen : const Color(0xFFDDDDE8),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}

// ─── Panel de envío de tarea ──────────────────────────────────────────────
class _SendTaskPanel extends ConsumerWidget {
  final Future<void> Function(TaskEntity task) onSend;
  const _SendTaskPanel({required this.onSend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(allTasksStreamProvider);
    final tasks = tasksAsync.valueOrNull
        ?.where((t) => !t.isCompleted)
        .toList() ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.dividerLight),
        ),
        child: const Center(
          child: Text(
            'No hay tareas pendientes para enviar',
            style: TextStyle(fontSize: 13, color: Color(0xFFAAAABB), fontFamily: 'Poppins'),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              'Selecciona una tarea pendiente y envíala al ESP32:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.take(6).length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final task = tasks[i];
              return ListTile(
                dense: true,
                leading: _PriorityDot(task.priority),
                title: Text(task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500)),
                subtitle: Text(
                        DateFormat('dd/MM/yyyy HH:mm', 'es_ES').format(task.dueDate),
                        style: const TextStyle(fontSize: 10, fontFamily: 'Poppins'),
                      ),
                trailing: IconButton(
                  icon: const Icon(Icons.send_rounded, size: 18),
                  color: AppTheme.kubikBlue,
                  tooltip: 'Enviar al ESP32',
                  onPressed: () => onSend(task),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Panel de info del dispositivo conectado ──────────────────────────────
class _DeviceInfoPanel extends StatelessWidget {
  final int? battery;
  final int mtu;
  final DateTime? lastSync;

  const _DeviceInfoPanel({
    required this.battery,
    required this.mtu,
    required this.lastSync,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.kubikBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.kubikBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.battery_std_rounded,
            label: 'Batería ESP32',
            value: battery != null ? '$battery%' : 'N/D',
            valueColor: battery != null
                ? (battery! >= 50 ? AppTheme.accentGreen : AppTheme.kubikCoral)
                : AppTheme.kubikDarkMid,
          ),
          const Divider(height: 20),
          _InfoRow(
            icon: Icons.data_array_rounded,
            label: 'MTU (payload máx.)',
            value: '${mtu}B por chunk',
          ),
          if (lastSync != null) ...[
            const Divider(height: 20),
            _InfoRow(
              icon: Icons.sync_rounded,
              label: 'Última sincronización',
              value: DateFormat('HH:mm:ss').format(lastSync!),
              valueColor: AppTheme.accentGreen,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.kubikBlue),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(
          fontSize: 12, fontFamily: 'Poppins', color: AppTheme.kubikDarkMid,
        )),
        const Spacer(),
        Text(value, style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
          color: valueColor ?? AppTheme.kubikDark,
        )),
      ],
    );
  }
}

// ─── Helpers visuales ────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionTitle({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700, color: AppTheme.kubikDark,
        )),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}

class _EmptyDevicesHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.kubikCoral.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.kubikCoral.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_tethering_off_rounded,
              size: 36, color: AppTheme.kubikCoral),
          const SizedBox(height: 8),
          const Text('No se encontraron dispositivos BLE.',
              style: TextStyle(fontSize: 13, fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600, color: AppTheme.kubikDark),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            'Asegúrate de que el ESP32 esté encendido y en modo BLE Server.\n'
            'El dispositivo debe anunciarse como "Kubik-ESP32".',
            style: const TextStyle(fontSize: 11, fontFamily: 'Poppins',
                color: AppTheme.kubikDarkMid),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  final TaskPriority priority;
  const _PriorityDot(this.priority);

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      TaskPriority.high   => AppTheme.priorityHigh,
      TaskPriority.medium => AppTheme.priorityMedium,
      TaskPriority.low    => AppTheme.priorityLow,
    };
    return Container(
      width: 10, height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
