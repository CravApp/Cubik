// lib/features/ble/presentation/widgets/ble_status_badge.dart
//
// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  BleStatusBadge – Widget para AppBar                                     ║
// ║                                                                           ║
// ║  Muestra en el AppBar:                                                    ║
// ║    • Ícono Bluetooth dinámico (coral = error/desc., azul = conectado)    ║
// ║    • Indicador de batería del ESP32 con porcentaje                        ║
// ║    • Animación de pulso cuando está conectado                             ║
// ║    • Toca el badge para navegar a la pantalla BLE                         ║
// ╚══════════════════════════════════════════════════════════════════════════╝

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/ble_device_entity.dart';
import '../providers/ble_providers.dart';

class BleStatusBadge extends ConsumerWidget {
  const BleStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connState = ref.watch(bleConnectionStateProvider);
    final battery   = ref.watch(bleBatteryProvider);
    final isConnected = connState.isConnected;
    final isScanning  = connState.isScanning;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.ble),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Indicador de batería (solo cuando conectado) ──────────
            if (isConnected && battery != null) ...[
              _BatteryIndicator(level: battery),
              const SizedBox(width: 6),
            ],

            // ── Ícono BLE ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _bgColor(connState).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isConnected
                        ? Icons.bluetooth_connected_rounded
                        : isScanning
                            ? Icons.bluetooth_searching_rounded
                            : Icons.bluetooth_rounded,
                    size: 18,
                    color: _iconColor(connState),
                  ),
                  // Punto verde de "activo" cuando está conectado
                  if (isConnected)
                    Positioned(
                      right: -2, top: -2,
                      child: Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                ],
              ),
            )
            .animate(
              onPlay: (c) => isScanning ? c.repeat() : null,
              target: isScanning ? 1 : 0,
            )
            .fade(
              duration: 600.ms,
              begin: 1.0,
              end: 0.4,
            )
            .then()
            .fade(
              duration: 600.ms,
              begin: 0.4,
              end: 1.0,
            ),
          ],
        ),
      ),
    );
  }

  Color _iconColor(BleConnectionState s) {
    if (s.isConnected) return AppTheme.kubikBlue;
    if (s.hasError || s == BleConnectionState.disconnected) return AppTheme.kubikCoral;
    return AppTheme.kubikBlue.withValues(alpha: 0.6);
  }

  Color _bgColor(BleConnectionState s) {
    if (s.isConnected) return AppTheme.kubikBlue;
    if (s.hasError || s == BleConnectionState.disconnected) return AppTheme.kubikCoral;
    return AppTheme.kubikBlue;
  }
}

// ─── Indicador de batería compacto ────────────────────────────────────────
class _BatteryIndicator extends StatelessWidget {
  final int level; // 0–100
  const _BatteryIndicator({required this.level});

  Color get _color {
    if (level >= 50) return AppTheme.accentGreen;
    if (level >= 20) return AppTheme.accentAmber;
    return AppTheme.kubikCoral;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ícono de batería
        SizedBox(
          width: 24,
          height: 12,
          child: CustomPaint(
            painter: _BatteryPainter(level: level, color: _color),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          '$level%',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _color,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

class _BatteryPainter extends CustomPainter {
  final int level;
  final Color color;
  const _BatteryPainter({required this.level, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = 1.2;
    final fillPaint = Paint()..color = color..style = PaintingStyle.fill;

    // Cuerpo de la batería
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width - 3, size.height),
      const Radius.circular(2),
    );
    canvas.drawRRect(body, paint);

    // Polo positivo (pequeño rectángulo en el extremo derecho)
    final pole = Rect.fromLTWH(
      size.width - 2, size.height * 0.3,
      2, size.height * 0.4,
    );
    canvas.drawRect(pole, fillPaint);

    // Nivel de carga (relleno proporcional)
    final fillWidth = ((size.width - 5) * level / 100).clamp(0.0, size.width - 5);
    if (fillWidth > 0) {
      final fill = RRect.fromRectAndRadius(
        Rect.fromLTWH(1.5, 1.5, fillWidth, size.height - 3),
        const Radius.circular(1),
      );
      canvas.drawRRect(fill, fillPaint);
    }
  }

  @override
  bool shouldRepaint(_BatteryPainter old) =>
      old.level != level || old.color != color;
}

// ─── Widget expandido para usar en paneles (no solo AppBar) ──────────────
class BleStatusChip extends ConsumerWidget {
  const BleStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connState   = ref.watch(bleConnectionStateProvider);
    final battery     = ref.watch(bleBatteryProvider);
    final device      = ref.watch(bleConnectedDeviceProvider);
    final isConnected = connState.isConnected;

    final bgColor   = isConnected ? AppTheme.kubikBlue : AppTheme.kubikCoral;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.ble),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bgColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_disabled_rounded,
              size: 16,
              color: bgColor,
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isConnected ? (device?.name ?? 'ESP32') : connState.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: bgColor,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (isConnected && battery != null)
                  Text(
                    'Batería: $battery%',
                    style: TextStyle(
                      fontSize: 9,
                      color: bgColor.withValues(alpha: 0.7),
                      fontFamily: 'Poppins',
                    ),
                  ),
              ],
            ),
            if (isConnected && battery != null) ...[
              const SizedBox(width: 8),
              _BatteryIndicator(level: battery),
            ],
          ],
        ),
      ),
    );
  }
}
