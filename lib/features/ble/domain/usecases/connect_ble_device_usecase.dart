// lib/features/ble/domain/usecases/connect_ble_device_usecase.dart
//
// Use Case: Conectar / Desconectar del ESP32 vía BLE.

import '../repositories/ble_repository.dart';

class ConnectBleDeviceUseCase {
  final BleRepository _repository;
  const ConnectBleDeviceUseCase(this._repository);

  /// [deviceId]: MAC address del ESP32 obtenida del escaneo.
  /// Retorna true si la conexión fue exitosa.
  Future<bool> connect(String deviceId) => _repository.connect(deviceId);

  Future<void> disconnect() => _repository.disconnect();
}
