// lib/features/ble/presentation/providers/ble_providers.dart
//
// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  PROVIDERS RIVERPOD – Feature BLE                                        ║
// ║                                                                           ║
// ║  Expone globalmente:                                                      ║
// ║    • bleStateProvider     → BleState completo (stream)                   ║
// ║    • bleConnectionProvider→ solo BleConnectionState                      ║
// ║    • bleBatteryProvider   → nivel de batería (int?)                      ║
// ║    • bleDevicesProvider   → lista de dispositivos escaneados             ║
// ║    • BleNotifier          → AsyncNotifier que gestiona acciones BLE       ║
// ╚══════════════════════════════════════════════════════════════════════════╝

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/ble_datasource.dart';
import '../../data/repositories/ble_repository_impl.dart';
import '../../domain/entities/ble_device_entity.dart';
import '../../domain/repositories/ble_repository.dart';
import '../../domain/usecases/scan_ble_devices_usecase.dart';
import '../../domain/usecases/connect_ble_device_usecase.dart';
import '../../domain/usecases/send_task_ble_usecase.dart';
import '../../../tasks/domain/entities/task_entity.dart';

// ─── Infraestructura: DataSource y Repositorio ────────────────────────────
final bleDatasourceProvider = Provider<BleDatasource>((ref) {
  final ds = BleDatasource();
  ref.onDispose(() => ds.dispose());
  return ds;
});

final bleRepositoryProvider = Provider<BleRepository>((ref) {
  final ds = ref.watch(bleDatasourceProvider);
  final repo = BleRepositoryImpl(ds);
  ref.onDispose(() => repo.dispose());
  return repo;
});

// ─── Use Cases ─────────────────────────────────────────────────────────────
final scanBleUseCaseProvider = Provider<ScanBleDevicesUseCase>(
  (ref) => ScanBleDevicesUseCase(ref.watch(bleRepositoryProvider)),
);

final connectBleUseCaseProvider = Provider<ConnectBleDeviceUseCase>(
  (ref) => ConnectBleDeviceUseCase(ref.watch(bleRepositoryProvider)),
);

final sendTaskBleUseCaseProvider = Provider<SendTaskBleUseCase>(
  (ref) => SendTaskBleUseCase(ref.watch(bleRepositoryProvider)),
);

// ─── Stream de estado BLE completo ────────────────────────────────────────
final bleStateStreamProvider = StreamProvider<BleState>((ref) {
  final repo = ref.watch(bleRepositoryProvider);
  // Emitir el estado inicial inmediatamente
  return repo.stateStream.distinct((a, b) =>
    a.connectionState == b.connectionState &&
    a.batteryLevel == b.batteryLevel &&
    a.alarmAcknowledged == b.alarmAcknowledged &&
    a.scannedDevices.length == b.scannedDevices.length
  );
});

// ─── Selectores derivados (evitan rebuilds innecesarios) ──────────────────

/// Solo el estado de conexión BLE
final bleConnectionStateProvider = Provider<BleConnectionState>((ref) {
  return ref.watch(bleStateStreamProvider).valueOrNull?.connectionState
      ?? BleConnectionState.disconnected;
});

/// Solo el nivel de batería del ESP32
final bleBatteryProvider = Provider<int?>((ref) {
  return ref.watch(bleStateStreamProvider).valueOrNull?.batteryLevel;
});

/// Lista de dispositivos encontrados en el último escaneo
final bleScannedDevicesProvider = Provider<List<BleDeviceEntity>>((ref) {
  return ref.watch(bleStateStreamProvider).valueOrNull?.scannedDevices ?? [];
});

/// Dispositivo actualmente conectado (null si no hay conexión)
final bleConnectedDeviceProvider = Provider<BleDeviceEntity?>((ref) {
  return ref.watch(bleStateStreamProvider).valueOrNull?.connectedDevice;
});

/// true cuando el ESP32 confirmó haber recibido y procesado la tarea
final bleAlarmAcknowledgedProvider = Provider<bool>((ref) {
  return ref.watch(bleStateStreamProvider).valueOrNull?.alarmAcknowledged ?? false;
});

/// MTU negociado con el ESP32 (tamaño máximo de chunk en bytes)
final bleMtuProvider = Provider<int>((ref) {
  return ref.watch(bleStateStreamProvider).valueOrNull?.mtu ?? 20;
});

/// Última sincronización exitosa
final bleLastSyncProvider = Provider<DateTime?>((ref) {
  return ref.watch(bleStateStreamProvider).valueOrNull?.lastSyncAt;
});

// ─── Notifier principal: gestiona todas las acciones BLE ─────────────────
class BleNotifier extends AsyncNotifier<BleState> {
  late BleRepository _repo;
  late ScanBleDevicesUseCase _scanUseCase;
  late ConnectBleDeviceUseCase _connectUseCase;
  late SendTaskBleUseCase _sendTaskUseCase;

  @override
  Future<BleState> build() async {
    _repo            = ref.watch(bleRepositoryProvider);
    _scanUseCase     = ref.watch(scanBleUseCaseProvider);
    _connectUseCase  = ref.watch(connectBleUseCaseProvider);
    _sendTaskUseCase = ref.watch(sendTaskBleUseCaseProvider);

    // Escuchar el stream y actualizar el estado del notifier
    ref.listen(bleStateStreamProvider, (_, next) {
      if (next.hasValue) state = AsyncData(next.value!);
    });

    return _repo.currentState;
  }

  // ── Acciones públicas ────────────────────────────────────────────────

  /// Inicia el escaneo BLE buscando dispositivos con nombre "Kubik"
  Future<void> startScan({String nameFilter = 'Kubik'}) async {
    state = AsyncData(state.valueOrNull?.copyWith(
      connectionState: BleConnectionState.scanning,
    ) ?? const BleState(connectionState: BleConnectionState.scanning));

    try {
      await _scanUseCase(nameFilter: nameFilter);
    } catch (e) {
      state = AsyncData(state.valueOrNull?.copyWith(
        connectionState: BleConnectionState.error,
        lastError: 'Error al escanear: $e',
      ) ?? const BleState(connectionState: BleConnectionState.error));
    }
  }

  Future<void> stopScan() => _scanUseCase.stop();

  /// Conecta con el ESP32 identificado por [deviceId]
  Future<bool> connect(String deviceId) async {
    state = AsyncData(state.valueOrNull?.copyWith(
      connectionState: BleConnectionState.connecting,
    ) ?? const BleState(connectionState: BleConnectionState.connecting));

    return _connectUseCase.connect(deviceId);
  }

  Future<void> disconnect() => _connectUseCase.disconnect();

  /// Envía la tarea completa al ESP32 con chunking automático
  Future<BleWriteResult> sendTask(TaskEntity task) => _sendTaskUseCase(task);

  /// Lee el nivel de batería manualmente (útil para refresh)
  Future<int?> refreshBattery() => _repo.readBatteryLevel();
}

final bleNotifierProvider = AsyncNotifierProvider<BleNotifier, BleState>(
  BleNotifier.new,
);
