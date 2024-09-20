// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realm_remote_device.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// ignore_for_file: type=lint
class RealmRemoteDevice extends _RealmRemoteDevice
    with RealmEntity, RealmObjectBase, RealmObject {
  RealmRemoteDevice(
    String id,
    String name,
    String phoneNumber,
    String secretKey,
    int commandCounter, {
    Iterable<RealmDeviceCommand> commands = const [],
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'name', name);
    RealmObjectBase.set(this, 'phoneNumber', phoneNumber);
    RealmObjectBase.set(this, 'secretKey', secretKey);
    RealmObjectBase.set(this, 'commandCounter', commandCounter);
    RealmObjectBase.set<RealmList<RealmDeviceCommand>>(
        this, 'commands', RealmList<RealmDeviceCommand>(commands));
  }

  RealmRemoteDevice._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get name => RealmObjectBase.get<String>(this, 'name') as String;
  @override
  set name(String value) => RealmObjectBase.set(this, 'name', value);

  @override
  String get phoneNumber =>
      RealmObjectBase.get<String>(this, 'phoneNumber') as String;
  @override
  set phoneNumber(String value) =>
      RealmObjectBase.set(this, 'phoneNumber', value);

  @override
  String get secretKey =>
      RealmObjectBase.get<String>(this, 'secretKey') as String;
  @override
  set secretKey(String value) => RealmObjectBase.set(this, 'secretKey', value);

  @override
  int get commandCounter =>
      RealmObjectBase.get<int>(this, 'commandCounter') as int;
  @override
  set commandCounter(int value) =>
      RealmObjectBase.set(this, 'commandCounter', value);

  @override
  RealmList<RealmDeviceCommand> get commands =>
      RealmObjectBase.get<RealmDeviceCommand>(this, 'commands')
          as RealmList<RealmDeviceCommand>;
  @override
  set commands(covariant RealmList<RealmDeviceCommand> value) =>
      throw RealmUnsupportedSetError();

  @override
  Stream<RealmObjectChanges<RealmRemoteDevice>> get changes =>
      RealmObjectBase.getChanges<RealmRemoteDevice>(this);

  @override
  Stream<RealmObjectChanges<RealmRemoteDevice>> changesFor(
          [List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<RealmRemoteDevice>(this, keyPaths);

  @override
  RealmRemoteDevice freeze() =>
      RealmObjectBase.freezeObject<RealmRemoteDevice>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'name': name.toEJson(),
      'phoneNumber': phoneNumber.toEJson(),
      'secretKey': secretKey.toEJson(),
      'commandCounter': commandCounter.toEJson(),
      'commands': commands.toEJson(),
    };
  }

  static EJsonValue _toEJson(RealmRemoteDevice value) => value.toEJson();
  static RealmRemoteDevice _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'name': EJsonValue name,
        'phoneNumber': EJsonValue phoneNumber,
        'secretKey': EJsonValue secretKey,
        'commandCounter': EJsonValue commandCounter,
      } =>
        RealmRemoteDevice(
          fromEJson(id),
          fromEJson(name),
          fromEJson(phoneNumber),
          fromEJson(secretKey),
          fromEJson(commandCounter),
          commands: fromEJson(ejson['commands']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(RealmRemoteDevice._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
        ObjectType.realmObject, RealmRemoteDevice, 'RealmRemoteDevice', [
      SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('name', RealmPropertyType.string),
      SchemaProperty('phoneNumber', RealmPropertyType.string),
      SchemaProperty('secretKey', RealmPropertyType.string),
      SchemaProperty('commandCounter', RealmPropertyType.int),
      SchemaProperty('commands', RealmPropertyType.object,
          linkTarget: 'RealmDeviceCommand',
          collectionType: RealmCollectionType.list),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

class RealmDeviceCommand extends _RealmDeviceCommand
    with RealmEntity, RealmObjectBase, RealmObject {
  RealmDeviceCommand(
    String command,
    String name,
  ) {
    RealmObjectBase.set(this, 'command', command);
    RealmObjectBase.set(this, 'name', name);
  }

  RealmDeviceCommand._();

  @override
  String get command => RealmObjectBase.get<String>(this, 'command') as String;
  @override
  set command(String value) => RealmObjectBase.set(this, 'command', value);

  @override
  String get name => RealmObjectBase.get<String>(this, 'name') as String;
  @override
  set name(String value) => RealmObjectBase.set(this, 'name', value);

  @override
  Stream<RealmObjectChanges<RealmDeviceCommand>> get changes =>
      RealmObjectBase.getChanges<RealmDeviceCommand>(this);

  @override
  Stream<RealmObjectChanges<RealmDeviceCommand>> changesFor(
          [List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<RealmDeviceCommand>(this, keyPaths);

  @override
  RealmDeviceCommand freeze() =>
      RealmObjectBase.freezeObject<RealmDeviceCommand>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'command': command.toEJson(),
      'name': name.toEJson(),
    };
  }

  static EJsonValue _toEJson(RealmDeviceCommand value) => value.toEJson();
  static RealmDeviceCommand _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'command': EJsonValue command,
        'name': EJsonValue name,
      } =>
        RealmDeviceCommand(
          fromEJson(command),
          fromEJson(name),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(RealmDeviceCommand._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
        ObjectType.realmObject, RealmDeviceCommand, 'RealmDeviceCommand', [
      SchemaProperty('command', RealmPropertyType.string),
      SchemaProperty('name', RealmPropertyType.string),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
