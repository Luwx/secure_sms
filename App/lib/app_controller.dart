import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:secure_sms/device_info.dart';
import 'package:secure_sms/realm/realm_device_repository.dart';

class AppController extends ChangeNotifier {
  AppController({required RemoteDeviceRepository storage}) : _storage = storage;

  final RemoteDeviceRepository _storage;

  List<RemoteDevice> _devices = [];

  List<RemoteDevice> get devices => _devices;

  Future<void> init() async {
    _devices = _storage.getAllDevices();
  }

  Future<Either<String, Unit>> saveDevice(RemoteDevice device) async {
    final deviceExists = _devices.any(
      (element) =>
          element.phoneNumber == device.phoneNumber ||
          element.name == device.name,
    );
    if (deviceExists) {
      return left('Dispositivo com mesmo nome ou numero já cadastrado');
    }
    _storage.addDevice(device);
    _devices = _storage.getAllDevices();
    notifyListeners();
    return right(unit);
  }

  Future<void> updateDevice(RemoteDevice device) async {
    _storage.updateDevice(device);
    _devices = _storage.getAllDevices();
    notifyListeners();
  }

  Future<void> deleteDevice(RemoteDevice device) async {
    _storage.deleteDevice(device);
    _devices = _storage.getAllDevices();
    notifyListeners();
  }

  Future<void> incrementCounter(String id) async {
    final device = _storage.getDeviceById(id);
    if (device == null) {
      return;
    }
    _storage.updateDevice(
      device.copyWith(
        commandCounter: device.commandCounter + 1,
      ),
    );
    _devices = _storage.getAllDevices();
    notifyListeners();
  }
}
