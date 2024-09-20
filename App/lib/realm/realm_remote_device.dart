import 'package:realm/realm.dart';

part 'realm_remote_device.realm.dart';

@RealmModel()
class _RealmRemoteDevice {
  @PrimaryKey()
  late String id;
  
  late String name;
  late String phoneNumber;
  late String secretKey;
  late int commandCounter;
  late List<_RealmDeviceCommand> commands;
}

@RealmModel()
class _RealmDeviceCommand {
  late String command;
  late String name;
}
