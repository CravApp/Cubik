// lib/features/ble/domain/entities/ble_device_entity.dart
//
// ╔══════════════════════════════════════════════════════════════════════╗
// ║  ENTIDADES DE DOMINIO – BLE                                         ║
// ║                                                                      ║
// ║  Define los contratos de datos puros del dominio BLE,               ║
// ║  completamente desacoplados de flutter_blue_plus.                   ║
// ╚══════════════════════════════════════════════════════════════════════╝

// ─── Estado de conexión ────────────────────────────────────────────────────
enum BleConnectionState {
  disconnected,   // Sin conexión activa
  scanning,       // Buscando dispositivos cercanos
  connecting,     // Estableciendo conexión con el ESP32
  connected,      // Conexión activa y lista para operar
  disconnecting,  // Cerrando la conexión
  error,          // Error irrecuperable (requiere reintentar)
}

extension BleConnectionStateX on BleConnectionState {
  bool get isConnected    => this == BleConnectionState.connected;
  bool get isScanning     => this == BleConnectionState.scanning;
  bool get isBusy         => this == BleConnectionState.connecting ||
                             this == BleConnectionState.disconnecting;
  bool get hasError       => this == BleConnectionState.error;

  String get label {
    switch (this) {
      case BleConnectionState.disconnected:  return 'Desconectado';
      case BleConnectionState.scanning:      return 'Buscando...';
      case BleConnectionState.connecting:    return 'Conectando...';
      case BleConnectionState.connected:     return 'Conectado';
      case BleConnectionState.disconnecting: return 'Desconectando...';
      case BleConnectionState.error:         return 'Error BLE';
    }
  }
}

// ─── Entidad de dispositivo BLE descubierto ───────────────────────────────
class BleDeviceEntity {
  /// ID único del dispositivo (MAC address en Android)
  final String id;

  /// Nombre anunciado por el dispositivo BLE
  final String name;

  /// Potencia de señal recibida (Received Signal Strength Indicator)
  /// Rango típico: -100 dBm (muy lejos) a -30 dBm (muy cerca)
  final int rssi;

  /// true si es el ESP32 de Kubik identificado por el nombre
  final bool isKubikDevice;

  const BleDeviceEntity({
    required this.id,
    required this.name,
    required this.rssi,
    this.isKubikDevice = false,
  });

  /// Convierte el RSSI en un porcentaje de calidad de señal (0–100)
  int get signalQuality {
    // Rango de referencia: -100 dBm = 0%, -30 dBm = 100%
    final clamped = rssi.clamp(-100, -30);
    return (((clamped + 100) / 70) * 100).round();
  }

  /// Icono descriptivo de la señal
  String get signalLabel {
    final q = signalQuality;
    if (q >= 75) return 'Excelente';
    if (q >= 50) return 'Buena';
    if (q >= 25) return 'Débil';
    return 'Muy débil';
  }

  BleDeviceEntity copyWith({String? id, String? name, int? rssi, bool? isKubikDevice}) {
    return BleDeviceEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      isKubikDevice: isKubikDevice ?? this.isKubikDevice,
    );
  }

  @override
  bool operator ==(Object other) => other is BleDeviceEntity && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

// ─── Estado global BLE (snapshot reactivo) ───────────────────────────────
class BleState {
  final BleConnectionState connectionState;
  final BleDeviceEntity? connectedDevice;
  final List<BleDeviceEntity> scannedDevices;
  final int? batteryLevel;          // 0–100 % (null = desconocido)
  final bool alarmAcknowledged;     // true cuando el ESP32 confirmó la tarea
  final String? lastError;          // Mensaje de error legible
  final int mtu;                    // MTU negociado (default 20 bytes)
  final DateTime? lastSyncAt;       // Última sincronización exitosa

  const BleState({
    this.connectionState = BleConnectionState.disconnected,
    this.connectedDevice,
    this.scannedDevices = const [],
    this.batteryLevel,
    this.alarmAcknowledged = false,
    this.lastError,
    this.mtu = 20,
    this.lastSyncAt,
  });

  BleState copyWith({
    BleConnectionState? connectionState,
    BleDeviceEntity? connectedDevice,
    bool clearDevice = false,
    List<BleDeviceEntity>? scannedDevices,
    int? batteryLevel,
    bool? alarmAcknowledged,
    String? lastError,
    bool clearError = false,
    int? mtu,
    DateTime? lastSyncAt,
  }) {
    return BleState(
      connectionState: connectionState ?? this.connectionState,
      connectedDevice: clearDevice ? null : (connectedDevice ?? this.connectedDevice),
      scannedDevices: scannedDevices ?? this.scannedDevices,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      alarmAcknowledged: alarmAcknowledged ?? this.alarmAcknowledged,
      lastError: clearError ? null : (lastError ?? this.lastError),
      mtu: mtu ?? this.mtu,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }
}

// ─── Resultado de escritura BLE ───────────────────────────────────────────
class BleWriteResult {
  final bool success;
  final int chunksWritten;
  final int totalBytes;
  final String? error;

  const BleWriteResult({
    required this.success,
    this.chunksWritten = 0,
    this.totalBytes = 0,
    this.error,
  });

  factory BleWriteResult.failure(String error) =>
      BleWriteResult(success: false, error: error);
}
