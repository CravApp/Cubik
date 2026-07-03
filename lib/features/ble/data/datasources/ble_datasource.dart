// lib/features/ble/data/datasources/ble_datasource.dart
//
// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  DATASOURCE BLE – flutter_blue_plus                                     ║
// ║                                                                          ║
// ║  Implementa toda la comunicación de bajo nivel con el hardware BLE.      ║
// ║  Maneja: escaneo, conexión GATT, descubrimiento de servicios,           ║
// ║  suscripción a notificaciones, escritura con chunking automático.        ║
// ║                                                                          ║
// ║  UUIDs del ESP32 Kubik (deben coincidir con el firmware del ESP32):     ║
// ║    Service UUID     : 4fafc201-1fb5-459e-8fcc-c5c9c331914b             ║
// ║    Write Char UUID  : beb5483e-36e1-4688-b7f5-ea07361b26a8             ║
// ║    Notify Char UUID : 6d68efe5-04b6-4a85-abc4-c2670b7bf7fd             ║
// ║    Battery Char UUID: 00002a19-0000-1000-8000-00805f9b34fb (BT SIG)    ║
// ╚══════════════════════════════════════════════════════════════════════════╝

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../domain/entities/ble_device_entity.dart';

// ─── UUIDs del ESP32 Kubik ────────────────────────────────────────────────
class KubikBleUuids {
  static const String serviceUuid      = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String writeCharUuid    = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
  static const String notifyCharUuid   = '6d68efe5-04b6-4a85-abc4-c2670b7bf7fd';
  static const String batteryCharUuid  = '00002a19-0000-1000-8000-00805f9b34fb';

  // Flags internos en el protocolo de notificación del ESP32
  static const String alarmConfirmFlag = 'ALARM_OK';
  static const String batteryPrefix    = 'BAT:';
  static const String chunkEnd         = 'END';   // El ESP32 espera este token al final
}

// ─── Excepción específica de BLE ──────────────────────────────────────────
class BleDatasourceException implements Exception {
  final String message;
  final dynamic original;
  const BleDatasourceException(this.message, [this.original]);
  @override
  String toString() => 'BleDatasourceException: $message';
}

// ─── DataSource principal ─────────────────────────────────────────────────
class BleDatasource {
  // Estado interno
  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeChar;
  BluetoothCharacteristic? _notifyChar;
  BluetoothCharacteristic? _batteryChar;
  int _mtu = 20; // Default BLE MTU sin cabecera ATT (23 - 3 bytes ATT = 20)

  // Streams hacia el repositorio
  final _stateController      = StreamController<BleConnectionState>.broadcast();
  final _devicesController    = StreamController<BleDeviceEntity>.broadcast();
  final _batteryController    = StreamController<int>.broadcast();
  final _alarmController      = StreamController<bool>.broadcast();
  final _errorController      = StreamController<String>.broadcast();

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<List<int>>? _notifySub;

  // ── Streams públicos ──────────────────────────────────────────────────
  Stream<BleConnectionState> get connectionStateStream => _stateController.stream;
  Stream<BleDeviceEntity>    get deviceFoundStream     => _devicesController.stream;
  Stream<int>                get batteryStream         => _batteryController.stream;
  Stream<bool>               get alarmAckStream        => _alarmController.stream;
  Stream<String>             get errorStream           => _errorController.stream;

  int get negotiatedMtu => _mtu;

  // ── ESCANEO ───────────────────────────────────────────────────────────
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 10),
    String? nameFilter,
  }) async {
    try {
      // Verificar que BLE esté disponible y encendido
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        throw BleDatasourceException(
          'Bluetooth no está activado. Por favor actívalo en Ajustes.',
        );
      }

      await FlutterBluePlus.stopScan(); // Detener escaneo previo si lo hubiera
      _stateController.add(BleConnectionState.scanning);

      _scanSub?.cancel();
      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final name = r.device.platformName;
          if (name.isEmpty) continue;
          if (nameFilter != null && !name.toLowerCase().contains(nameFilter.toLowerCase())) {
            continue;
          }
          final entity = BleDeviceEntity(
            id: r.device.remoteId.str,
            name: name,
            rssi: r.rssi,
            isKubikDevice: name.toLowerCase().contains('kubik'),
          );
          _devicesController.add(entity);
        }
      });

      await FlutterBluePlus.startScan(timeout: timeout);
      await Future.delayed(timeout);
      _stateController.add(BleConnectionState.disconnected);
    } catch (e) {
      _errorController.add('Error al escanear: $e');
      _stateController.add(BleConnectionState.error);
      rethrow;
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    _stateController.add(BleConnectionState.disconnected);
  }

  // ── CONEXIÓN ──────────────────────────────────────────────────────────
  Future<bool> connect(String deviceId) async {
    try {
      _stateController.add(BleConnectionState.connecting);

      // Obtener referencia al dispositivo por su MAC
      _device = BluetoothDevice.fromId(deviceId);

      // Cancelar suscripción previa al estado de conexión
      _connSub?.cancel();
      _connSub = _device!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _onDeviceDisconnected();
        }
      });

      // Conectar con timeout de 15 segundos
      await _device!.connect(timeout: const Duration(seconds: 15));

      // Negociar MTU máximo con el ESP32 (512 bytes es el máximo BLE 4.2+)
      // En la práctica, el ESP32 negociará entre 23 y 512 bytes
      _mtu = await _device!.requestMtu(512);
      // Restamos 3 bytes de cabecera ATT para obtener el payload real
      _mtu = _mtu - 3;
      if (kDebugMode) debugPrint('[BLE] MTU negociado: $_mtu bytes de payload');

      // Descubrir servicios GATT
      await _device!.discoverServices();
      final services = _device!.servicesList;

      // Localizar el servicio Kubik y sus características
      final kubikService = services.where(
        (s) => s.uuid.toString().toLowerCase() == KubikBleUuids.serviceUuid,
      ).firstOrNull;

      if (kubikService == null) {
        // Si no hay servicio Kubik, buscar al menos la característica de batería
        // en el servicio estándar de batería BLE (0x180F)
        _findBatteryChar(services);
        throw BleDatasourceException(
          'Servicio Kubik no encontrado. ¿Está el firmware correcto en el ESP32?',
        );
      }

      for (final char in kubikService.characteristics) {
        final uuid = char.uuid.toString().toLowerCase();
        if (uuid == KubikBleUuids.writeCharUuid) {
          _writeChar = char;
        } else if (uuid == KubikBleUuids.notifyCharUuid) {
          _notifyChar = char;
        } else if (uuid == KubikBleUuids.batteryCharUuid) {
          _batteryChar = char;
        }
      }

      // También buscar batería en servicios estándar
      _findBatteryChar(services);

      // Suscribir a las notificaciones del ESP32
      if (_notifyChar != null) {
        await _notifyChar!.setNotifyValue(true);
        _notifySub = _notifyChar!.lastValueStream.listen(_handleNotification);
        if (kDebugMode) debugPrint('[BLE] Suscrito a notificaciones');
      }

      // Leer batería inicial
      await _readBatteryOnce();

      _stateController.add(BleConnectionState.connected);
      if (kDebugMode) debugPrint('[BLE] Conectado a $deviceId con MTU=$_mtu');
      return true;

    } catch (e) {
      _errorController.add('Error al conectar: $e');
      _stateController.add(BleConnectionState.error);
      await _cleanup();
      return false;
    }
  }

  void _findBatteryChar(List<BluetoothService> services) {
    for (final service in services) {
      for (final char in service.characteristics) {
        if (char.uuid.toString().toLowerCase() == KubikBleUuids.batteryCharUuid) {
          _batteryChar = char;
          return;
        }
      }
    }
  }

  Future<void> _readBatteryOnce() async {
    try {
      if (_batteryChar == null) return;
      final value = await _batteryChar!.read();
      if (value.isNotEmpty) {
        _batteryController.add(value[0].clamp(0, 100));
      }
    } catch (_) {
      // No crítico — la batería se actualizará por notificación
    }
  }

  // ── MANEJO DE NOTIFICACIONES (ESP32 → Flutter) ───────────────────────
  void _handleNotification(List<int> value) {
    if (value.isEmpty) return;
    final raw = utf8.decode(value, allowMalformed: true).trim();
    if (kDebugMode) debugPrint('[BLE] Notificación recibida: "$raw"');

    // 1. Confirmación de tarea procesada por el ESP32
    if (raw.contains(KubikBleUuids.alarmConfirmFlag)) {
      _alarmController.add(true);
      return;
    }

    // 2. Actualización de batería: "BAT:85" → 85%
    if (raw.startsWith(KubikBleUuids.batteryPrefix)) {
      final levelStr = raw.substring(KubikBleUuids.batteryPrefix.length).trim();
      final level = int.tryParse(levelStr);
      if (level != null) {
        _batteryController.add(level.clamp(0, 100));
      }
      return;
    }

    // 3. Otros mensajes de estado del ESP32 (extensible)
    if (kDebugMode) debugPrint('[BLE] Mensaje ESP32 no reconocido: "$raw"');
  }

  // ── ESCRITURA CON CHUNKING AUTOMÁTICO ────────────────────────────────
  //
  // El MTU BLE limita los bytes por paquete. Si la tarea es larga,
  // se divide en chunks y se envían secuencialmente con un pequeño delay
  // entre cada uno para no saturar el buffer del ESP32.
  //
  // Protocolo acordado con el firmware ESP32:
  //   CHUNK:1/3|<datos>   → primer chunk de 3
  //   CHUNK:2/3|<datos>   → segundo chunk
  //   CHUNK:3/3|<datos>   → último chunk (ESP32 reensambla y procesa)
  //   Si cabe en un paquete: SINGLE|<datos>
  //
  Future<({bool success, int chunks, int bytes, String? error})> writeWithChunking(
    BluetoothCharacteristic char,
    String payload,
  ) async {
    final bytes = utf8.encode(payload);
    final totalBytes = bytes.length;

    // Reservar bytes para la cabecera del protocolo (ej: "CHUNK:1/9|")
    // Estimamos 12 bytes de overhead de cabecera en el peor caso
    final chunkSize = _mtu - 12;

    if (chunkSize <= 0) {
      return (success: false, chunks: 0, bytes: 0, error: 'MTU demasiado pequeño: $_mtu');
    }

    // Si cabe en un solo paquete
    if (bytes.length <= _mtu - 7) { // 7 bytes para "SINGLE|"
      final packet = 'SINGLE|$payload';
      await char.write(utf8.encode(packet), withoutResponse: false);
      return (success: true, chunks: 1, bytes: totalBytes, error: null);
    }

    // Dividir en chunks
    final chunks = <List<int>>[];
    for (var i = 0; i < bytes.length; i += chunkSize) {
      final end = (i + chunkSize).clamp(0, bytes.length);
      chunks.add(bytes.sublist(i, end));
    }

    final totalChunks = chunks.length;
    if (kDebugMode) {
      debugPrint('[BLE] Chunking: $totalBytes bytes → $totalChunks chunks de ${chunkSize}B');
    }

    for (var i = 0; i < chunks.length; i++) {
      final header = utf8.encode('CHUNK:${i + 1}/$totalChunks|');
      final packet = [...header, ...chunks[i]];

      try {
        await char.write(packet, withoutResponse: false);
        // Delay entre chunks para no saturar el RX buffer del ESP32
        // El ESP32 necesita tiempo para procesar y liberar el buffer GATT
        if (i < chunks.length - 1) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      } catch (e) {
        return (
          success: false,
          chunks: i,
          bytes: i * chunkSize,
          error: 'Error en chunk ${i + 1}/$totalChunks: $e'
        );
      }
    }

    return (success: true, chunks: totalChunks, bytes: totalBytes, error: null);
  }

  Future<BleWriteResult> sendRaw(String characteristicUuid, List<int> rawBytes) async {
    if (_device == null || _writeChar == null) {
      return BleWriteResult.failure('No conectado o característica no disponible');
    }
    try {
      await _writeChar!.write(rawBytes, withoutResponse: false);
      return BleWriteResult(success: true, chunksWritten: 1, totalBytes: rawBytes.length);
    } catch (e) {
      return BleWriteResult.failure('Error de escritura: $e');
    }
  }

  Future<int?> readBatteryLevel() async {
    try {
      if (_batteryChar == null) return null;
      final value = await _batteryChar!.read();
      if (value.isNotEmpty) return value[0].clamp(0, 100);
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── DESCONEXIÓN ───────────────────────────────────────────────────────
  Future<void> disconnect() async {
    _stateController.add(BleConnectionState.disconnecting);
    await _cleanup();
    _stateController.add(BleConnectionState.disconnected);
  }

  void _onDeviceDisconnected() {
    if (kDebugMode) debugPrint('[BLE] Dispositivo desconectado');
    _writeChar = null;
    _notifyChar = null;
    _batteryChar = null;
    _mtu = 20;
    _stateController.add(BleConnectionState.disconnected);
  }

  Future<void> _cleanup() async {
    _notifySub?.cancel();
    _notifySub = null;
    _connSub?.cancel();
    _connSub = null;
    try {
      await _device?.disconnect();
    } catch (_) {}
    _device = null;
    _writeChar = null;
    _notifyChar = null;
    _batteryChar = null;
    _mtu = 20;
  }

  // ── LIBERAR RECURSOS ──────────────────────────────────────────────────
  Future<void> dispose() async {
    await _cleanup();
    await _stateController.close();
    await _devicesController.close();
    await _batteryController.close();
    await _alarmController.close();
    await _errorController.close();
    _scanSub?.cancel();
  }

  // ── ACCESORES INTERNOS para el repositorio ────────────────────────────
  BluetoothCharacteristic? get writeCharacteristic  => _writeChar;
  BluetoothCharacteristic? get notifyCharacteristic => _notifyChar;
  bool get isConnected => _device != null && _writeChar != null;
}
