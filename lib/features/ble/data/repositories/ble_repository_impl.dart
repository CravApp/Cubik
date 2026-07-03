// lib/features/ble/data/repositories/ble_repository_impl.dart
//
// Implementación concreta del BleRepository.
// Traduce los streams del DataSource al modelo de dominio (BleState).

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/ble_device_entity.dart';
import '../../domain/repositories/ble_repository.dart';
import '../datasources/ble_datasource.dart';
import '../../../tasks/domain/entities/task_entity.dart';

class BleRepositoryImpl implements BleRepository {
  final BleDatasource _datasource;

  // Estado interno mutable
  BleState _state = const BleState();

  // StreamController principal que emite BleState al exterior
  final _stateController = StreamController<BleState>.broadcast();

  // Suscripciones internas a los streams del datasource
  StreamSubscription<BleConnectionState>? _connSub;
  StreamSubscription<BleDeviceEntity>? _deviceSub;
  StreamSubscription<int>? _batterySub;
  StreamSubscription<bool>? _alarmSub;
  StreamSubscription<String>? _errorSub;

  // Cache de dispositivos escaneados (por ID para evitar duplicados)
  final Map<String, BleDeviceEntity> _scannedMap = {};

  BleRepositoryImpl(this._datasource) {
    _bindDatasourceStreams();
  }

  // ── Vincular streams del datasource ─────────────────────────────────
  void _bindDatasourceStreams() {
    _connSub = _datasource.connectionStateStream.listen((connState) {
      // Al iniciar un escaneo, limpiar la lista de dispositivos previos
      if (connState == BleConnectionState.scanning) _scannedMap.clear();

      // Al desconectar, limpiar dispositivo conectado
      final clearDevice = connState == BleConnectionState.disconnected ||
                          connState == BleConnectionState.error;

      _emit(_state.copyWith(
        connectionState: connState,
        clearDevice: clearDevice && _state.connectionState != BleConnectionState.connecting,
        scannedDevices: List.from(_scannedMap.values),
      ));
    });

    _deviceSub = _datasource.deviceFoundStream.listen((device) {
      _scannedMap[device.id] = device;
      // Ordenar: primero dispositivos Kubik, luego por señal descendente
      final sorted = _scannedMap.values.toList()
        ..sort((a, b) {
          if (a.isKubikDevice != b.isKubikDevice) {
            return a.isKubikDevice ? -1 : 1;
          }
          return b.rssi.compareTo(a.rssi);
        });
      _emit(_state.copyWith(scannedDevices: sorted));
    });

    _batterySub = _datasource.batteryStream.listen((level) {
      _emit(_state.copyWith(batteryLevel: level));
    });

    _alarmSub = _datasource.alarmAckStream.listen((ack) {
      _emit(_state.copyWith(alarmAcknowledged: ack));
      // Auto-reset después de 3 segundos para que la UI pueda volver a disparar
      Future.delayed(const Duration(seconds: 3), () {
        _emit(_state.copyWith(alarmAcknowledged: false));
      });
    });

    _errorSub = _datasource.errorStream.listen((error) {
      _emit(_state.copyWith(
        connectionState: BleConnectionState.error,
        lastError: error,
      ));
    });
  }

  void _emit(BleState newState) {
    _state = newState;
    if (!_stateController.isClosed) _stateController.add(_state);
  }

  // ── Implementación de BleRepository ──────────────────────────────────
  @override
  Stream<BleState> get stateStream => _stateController.stream;

  @override
  BleState get currentState => _state;

  @override
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 10),
    String? nameFilter,
  }) => _datasource.startScan(timeout: timeout, nameFilter: nameFilter);

  @override
  Future<void> stopScan() => _datasource.stopScan();

  @override
  Future<bool> connect(String deviceId) async {
    final success = await _datasource.connect(deviceId);
    if (success) {
      // Actualizar dispositivo conectado en el estado
      final device = _scannedMap[deviceId];
      _emit(_state.copyWith(
        connectionState: BleConnectionState.connected,
        connectedDevice: device ?? const BleDeviceEntity(
          id: '', name: 'ESP32 Kubik', rssi: 0, isKubikDevice: true,
        ),
        mtu: _datasource.negotiatedMtu,
        clearError: true,
      ));
    }
    return success;
  }

  @override
  Future<void> disconnect() => _datasource.disconnect();

  // ── Serialización de tarea y envío con chunking ──────────────────────
  //
  // Formato de payload acordado con el firmware ESP32:
  //   TIT:<título>\nDES:<descripción>\nFEC:<fecha>\nHOR:<hora>\nPRI:<prioridad>
  //
  // El ESP32 parseará este formato para mostrar en su display y
  // programar su alarma local.
  //
  @override
  Future<BleWriteResult> sendTask(TaskEntity task) async {
    final writeChar = _datasource.writeCharacteristic;
    if (writeChar == null) {
      return BleWriteResult.failure('Característica de escritura no disponible');
    }

    try {
      // Serializar la tarea como texto estructurado
      final payload = _serializeTask(task);
      if (kDebugMode) debugPrint('[BLE] Enviando tarea (${payload.length} bytes): $payload');

      final result = await _datasource.writeWithChunking(writeChar, payload);

      if (result.success) {
        _emit(_state.copyWith(lastSyncAt: DateTime.now(), clearError: true));
        return BleWriteResult(
          success: true,
          chunksWritten: result.chunks,
          totalBytes: result.bytes,
        );
      } else {
        return BleWriteResult.failure(result.error ?? 'Error desconocido');
      }
    } catch (e) {
      return BleWriteResult.failure('Error al enviar tarea: $e');
    }
  }

  /// Serializa TaskEntity en el protocolo de texto del ESP32
  String _serializeTask(TaskEntity task) {
    final dateFmt = DateFormat('dd/MM/yyyy', 'es_ES');
    final timeFmt = DateFormat('HH:mm', 'es_ES');
    final priorityStr = _priorityLabel(task.priority);

    final buffer = StringBuffer()
      ..write('TIT:${_sanitize(task.title)}\n')
      ..write('DES:${_sanitize(task.description)}\n')
      ..write('FEC:${dateFmt.format(task.dueDate)}\n')
      ..write('HOR:${timeFmt.format(task.dueDate)}\n')
      ..write('PRI:$priorityStr\n')
      ..write('COM:${task.isCompleted ? '1' : '0'}');

    return buffer.toString();
  }

  /// Elimina caracteres que podrían romper el protocolo del ESP32
  String _sanitize(String input) =>
      input.replaceAll('\n', ' ').replaceAll('|', '/').trim();

  String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:    return 'BAJA';
      case TaskPriority.medium: return 'MEDIA';
      case TaskPriority.high:   return 'ALTA';
    }
  }

  @override
  Future<BleWriteResult> writeRaw(String characteristicUuid, List<int> bytes) =>
      _datasource.sendRaw(characteristicUuid, bytes);

  @override
  Future<int?> readBatteryLevel() => _datasource.readBatteryLevel();

  @override
  Future<void> dispose() async {
    _connSub?.cancel();
    _deviceSub?.cancel();
    _batterySub?.cancel();
    _alarmSub?.cancel();
    _errorSub?.cancel();
    await _stateController.close();
    await _datasource.dispose();
  }
}
