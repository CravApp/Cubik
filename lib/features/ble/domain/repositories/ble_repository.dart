// lib/features/ble/domain/repositories/ble_repository.dart
//
// Contrato abstracto del repositorio BLE.
// La capa de presentación depende SOLO de esta interfaz (Dependency Inversion).

import '../entities/ble_device_entity.dart';
import '../../../tasks/domain/entities/task_entity.dart';

abstract class BleRepository {
  // ── Estado reactivo ──────────────────────────────────────────────────
  /// Stream del estado BLE completo (conexión, batería, alarma, etc.)
  Stream<BleState> get stateStream;

  /// Snapshot síncrono del estado actual
  BleState get currentState;

  // ── Escaneo ──────────────────────────────────────────────────────────
  /// Inicia el escaneo BLE. Emite dispositivos en [stateStream].
  /// [timeout]: máximo tiempo de escaneo (default 10 s)
  /// [nameFilter]: si se provee, solo incluye dispositivos cuyo nombre lo contiene
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 10),
    String? nameFilter,
  });

  /// Detiene el escaneo activo
  Future<void> stopScan();

  // ── Conexión ─────────────────────────────────────────────────────────
  /// Conecta con el dispositivo ESP32 identificado por [deviceId].
  /// Descubre servicios y suscribe a características automáticamente.
  Future<bool> connect(String deviceId);

  /// Desconecta el dispositivo activo
  Future<void> disconnect();

  // ── Escritura: Envío de tarea al ESP32 ───────────────────────────────
  /// Serializa [task] en texto y lo escribe en la característica de escritura.
  /// Implementa chunking automático si el payload supera el MTU negociado.
  Future<BleWriteResult> sendTask(TaskEntity task);

  /// Escribe bytes raw en una característica (uso avanzado)
  Future<BleWriteResult> writeRaw(String characteristicUuid, List<int> bytes);

  // ── Lectura manual ────────────────────────────────────────────────────
  /// Lee sincrónicamente el nivel de batería del ESP32
  Future<int?> readBatteryLevel();

  // ── Limpieza ─────────────────────────────────────────────────────────
  /// Libera todos los recursos (streams, conexiones)
  Future<void> dispose();
}
