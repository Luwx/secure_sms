import 'dart:convert';

import 'package:equatable/equatable.dart';

class RemoteDevice extends Equatable {
  const RemoteDevice({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.secretKey,
    required this.commands,
    required this.commandCounter,
  });

  factory RemoteDevice.fromJson(String source) =>
      RemoteDevice.fromMap(json.decode(source) as Map<String, dynamic>);

  factory RemoteDevice.fromMap(Map<String, dynamic> map) {
    return RemoteDevice(
      id: map['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: map['name'] as String,
      phoneNumber: map['phonenumber'] as String,
      secretKey: map['key'] as String,
      commandCounter: map['counter'] as int? ?? 0,
      commands: map['commands'] != null
          ? List<DeviceCommand>.from(
              (map['commands'] as List<dynamic>)
                  .map((x) => DeviceCommand.fromMap(x as Map<String, dynamic>)),
            )
          : [],
    );
  }

  final String id;
  final String name;
  final String phoneNumber;
  final String secretKey;
  final List<DeviceCommand> commands;
  final int commandCounter;

  @override
  List<Object?> get props => [name, phoneNumber, secretKey];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'num': phoneNumber,
      'key': secretKey,
      'comms': commands.map((x) => x.toMap()).toList(),
      'counter': commandCounter,
    };
  }

  String toJson() => json.encode(toMap());

  RemoteDevice copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? secretKey,
    List<DeviceCommand>? commands,
    int? commandCounter,
  }) {
    return RemoteDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      secretKey: secretKey ?? this.secretKey,
      commands: commands ?? this.commands,
      commandCounter: commandCounter ?? this.commandCounter,
    );
  }
}

class DeviceCommand extends Equatable {
  const DeviceCommand({
    required this.command,
    required this.name,
  });

  factory DeviceCommand.fromJson(String source) =>
      DeviceCommand.fromMap(json.decode(source) as Map<String, dynamic>);

  factory DeviceCommand.fromMap(Map<String, dynamic> map) {
    return DeviceCommand(
      command: map['command'] as String,
      name: map['name'] as String,
    );
  }

  final String command;
  final String name;

  @override
  List<Object?> get props => [command, name];

  Map<String, dynamic> toMap() {
    return {
      'command': command,
      'name': name,
    };
  }

  String toJson() => json.encode(toMap());
}
