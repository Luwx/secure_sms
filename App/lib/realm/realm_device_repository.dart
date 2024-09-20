// import 'package:realm/realm.dart';
import 'package:realm/realm.dart';
import 'package:secure_sms/device_info.dart';
import 'package:secure_sms/realm/realm_remote_device.dart';
//import 'remote_device.dart';

class RemoteDeviceRepository {
  RemoteDeviceRepository({required Realm realm}) : _realm = realm;
  final Realm _realm;

  // Add a new device
  void addDevice(RemoteDevice device) {
    _realm.write(() {
      _realm.add(RealmRemoteDeviceConversion.fromOriginalObject(device));
    });
  }

  // Get all devices
  List<RemoteDevice> getAllDevices() {
    return _realm
        .all<RealmRemoteDevice>()
        .map((e) => e.toOriginalObject())
        .toList();
  }

  // Update a device
  void updateDevice(RemoteDevice device) {
    final savedDevice = _realm.find<RealmRemoteDevice>(device.id);
    if (savedDevice == null) {
      return;
    }
    _realm.write(() {
      savedDevice
        ..name = device.name
        ..phoneNumber = device.phoneNumber
        ..secretKey = device.secretKey
        ..commandCounter = device.commandCounter
        ..commands.clear();
      savedDevice.commands.addAll(
        device.commands
            .map(
              (command) => RealmDeviceCommand(
                command.command,
                command.name,
              ),
            )
            .toList(),
      );
    });
  }

  // Delete a device
  void deleteDevice(RemoteDevice device) {
    final item = _realm.find<RealmRemoteDevice>(device.id)!;
    _realm.write(() {
      _realm.delete(item);
    });
  }

  // Get a device by id
  RemoteDevice? getDeviceById(String id) {
    return _realm.find<RealmRemoteDevice>(id)?.toOriginalObject();
  }

  // Close the realm instance
  void close() {
    _realm.close();
  }
}

extension RealmRemoteDeviceConversion on RealmRemoteDevice {
  RemoteDevice toOriginalObject() {
    return RemoteDevice(
      id: id,
      name: name,
      phoneNumber: phoneNumber,
      secretKey: secretKey,
      commandCounter: commandCounter,
      commands: commands
          .map(
            (command) => DeviceCommand(
              command: command.command,
              name: command.name,
            ),
          )
          .toList(),
    );
  }

  static RealmRemoteDevice fromOriginalObject(RemoteDevice device) {
    return RealmRemoteDevice(
      device.id,
      device.name,
      device.phoneNumber,
      device.secretKey,
      device.commandCounter,
      commands: device.commands
          .map(
            (command) => RealmDeviceCommand(
              command.command,
              command.name,
            ),
          )
          .toList(),
    );
  }
}
