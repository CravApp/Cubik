// lib/features/ble/domain/usecases/send_task_ble_usecase.dart
//
// Use Case: Serializar y enviar una tarea completa al ESP32.
// Delega el chunking al repositorio para mantener este caso de uso limpio.

import '../entities/ble_device_entity.dart';
import '../repositories/ble_repository.dart';
import '../../../tasks/domain/entities/task_entity.dart';

class SendTaskBleUseCase {
  final BleRepository _repository;
  const SendTaskBleUseCase(this._repository);

  /// Envía [task] al ESP32 conectado.
  /// Lanza [BleNotConnectedException] si no hay conexión activa.
  Future<BleWriteResult> call(TaskEntity task) async {
    if (!_repository.currentState.connectionState.isConnected) {
      return BleWriteResult.failure('No hay conexión BLE activa');
    }
    return _repository.sendTask(task);
  }
}

class BleNotConnectedException implements Exception {
  final String message;
  const BleNotConnectedException([this.message = 'ESP32 no conectado']);
  @override
  String toString() => 'BleNotConnectedException: $message';
}
