// lib/features/ble/domain/usecases/scan_ble_devices_usecase.dart
//
// Use Case: Iniciar escaneo BLE filtrado por nombre del ESP32 Kubik.
// Sigue el patrón Single Responsibility: un caso de uso = una acción.

import '../repositories/ble_repository.dart';

class ScanBleDevicesUseCase {
  final BleRepository _repository;
  const ScanBleDevicesUseCase(this._repository);

  /// Inicia escaneo buscando el dispositivo ESP32 de Kubik.
  /// Por convención el ESP32 anuncia su nombre como "Kubik-ESP32" o similar.
  Future<void> call({
    Duration timeout = const Duration(seconds: 10),
    String nameFilter = 'Kubik',
  }) {
    return _repository.startScan(timeout: timeout, nameFilter: nameFilter);
  }

  Future<void> stop() => _repository.stopScan();
}
