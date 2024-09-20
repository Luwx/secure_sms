// import 'dart:convert';

// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:secure_sms/device_info.dart';

// class RemoteDeviceRepository {
//   const RemoteDeviceRepository(this._secureStorage);

//   final FlutterSecureStorage _secureStorage;

//   Future<List<RemoteDevice>> getDevices() async {
//     final deviceInfoJson = await _secureStorage.read(key: 'devices');
//     if (deviceInfoJson == null) {
//       return [];
//     }
//     if (deviceInfoJson.isEmpty) {
//       return [];
//     }

//     final decoded = jsonDecode(deviceInfoJson) as Map<String, dynamic>;

//     if (decoded['devices'] == null) {
//       return [];
//     }

//     return List<RemoteDevice>.from(
//       (decoded['devices'] as List<dynamic>)
//           .map((x) => RemoteDevice.fromMap(x as Map<String, dynamic>)),
//     );
//   }

//   Future<void> saveDevices(List<RemoteDevice> devices) async {
//     final devicesJson = jsonEncode({
//       'devices': devices.map((e) => e.toMap()).toList(),
//     });
//     await _secureStorage.write(key: 'devices', value: devicesJson);
//   }

//   Future<void> saveDevice(RemoteDevice device) async {
//     final devices = await getDevices();
//     final index = devices.indexWhere(
//       (element) => element.phoneNumber == device.phoneNumber,
//     );
//     if (index == -1) {
//       devices.add(device);
//     } else {
//       devices[index] = device;
//     }
//     await saveDevices(devices);
//   }

//   Future<RemoteDevice?> getDevice() async {
//     final deviceInfo = await _secureStorage.read(key: 'deviceInfo');
//     if (deviceInfo == null) {
//       return null;
//     }
//     return RemoteDevice.fromJson(deviceInfo);
//   }

//   Future<void> setCounter(int counter) async {
//     await _secureStorage.write(key: 'actionCounter', value: counter.toString());
//   }

//   Future<int?> getCounter() async {
//     final counter = await _secureStorage.read(key: 'actionCounter');
//     if (counter == null) {
//       return null;
//     }
//     return int.parse(counter);
//   }

//   Future<void> delete() async {
//     await _secureStorage.delete(key: 'deviceInfo');
//     await _secureStorage.delete(key: 'actionCounter');
//   }
// }
