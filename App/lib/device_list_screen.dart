import 'package:flutter/material.dart';
import 'package:secure_sms/app_controller.dart';
import 'package:secure_sms/device_info.dart';
import 'package:secure_sms/main.dart';
import 'package:secure_sms/shared_widgets/app_drawer.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  final appController = getIt<AppController>();
  List<RemoteDevice> get devices => getIt<AppController>().devices;

  @override
  void initState() {
    super.initState();
    //devices = widget.repository.getAllDevices();
  }

  void _deleteDevice(RemoteDevice device) {
    appController.deleteDevice(device);
  }

  void _deleteCommand(RemoteDevice device, DeviceCommand command) {
    device.commands.remove(command);
    appController.updateDevice(device);
  }

  Future<void> _addCommand(RemoteDevice device) async {
    final result = await showDialog<DeviceCommand>(
      context: context,
      builder: (BuildContext context) {
        var name = '';
        var command = '';
        return AlertDialog(
          title: const Text('Add Command'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Command Name'),
                onChanged: (value) => name = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Command'),
                onChanged: (value) => command = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () => Navigator.of(context).pop(
                DeviceCommand(command: command, name: name),
              ),
            ),
          ],
        );
      },
    );

    if (result != null) {
      device.commands.add(result);
      await appController.updateDevice(device);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
      ),
      drawer:
          const AppDrawer(selectedDestination: AppDrawerDestination.devices),
      body: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final device = devices[index];
          return Card(
            // ignore: prefer_int_literals
            margin: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ListTile(
                  title: Text(device.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteDevice(device),
                  ),
                ),
                const Divider(),
                ...device.commands.map(
                  (command) => ListTile(
                    title: Text(command.name),
                    subtitle: Text(command.command),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteCommand(device, command),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Add Command'),
                  onTap: () => _addCommand(device),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          // Implement adding a new device
        },
      ),
    );
  }
}
