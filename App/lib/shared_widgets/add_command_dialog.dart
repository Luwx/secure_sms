import 'package:flutter/material.dart';
import 'package:secure_sms/device_info.dart';

class AddCommandDialog extends StatefulWidget {
  const AddCommandDialog({
    required this.devices,
    this.initialDevice,
    super.key,
  });
  final List<RemoteDevice> devices;
  final RemoteDevice? initialDevice;

  @override
  State<AddCommandDialog> createState() => _AddCommandDialogState();
}

class _AddCommandDialogState extends State<AddCommandDialog> {
  final _formKey = GlobalKey<FormState>();
  RemoteDevice? selectedDevice;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController commandController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedDevice = widget.initialDevice;
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'add_command_dialog',
      child: AlertDialog(
        title: const Text('Adicionar novo comando'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownMenu<RemoteDevice>(
                  requestFocusOnTap: false,
                  expandedInsets: EdgeInsets.zero,
                  enableSearch: false,
                  initialSelection: widget.initialDevice,
                  label: const Text('Dispositivo'),
                  //inputDecorationTheme: escolhaInputDecorationTheme(context),
                  onSelected: (device) {
                    if (device != null) {
                      setState(() {
                        selectedDevice = device;
                      });
                    }
                  },
                  dropdownMenuEntries: widget.devices
                      .map(
                        (device) => DropdownMenuEntry(
                          value: device,
                          label: device.name,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(labelText: 'Nome do comando'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Insira um nome para o comando';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: commandController,
                  decoration: const InputDecoration(labelText: 'Comando'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Insira um comando';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text('Adicionar comando'),
            onPressed: () {
              if (_formKey.currentState!.validate() && selectedDevice != null) {
                Navigator.of(context).pop(
                  selectedDevice!.copyWith(
                    commands: [
                      ...selectedDevice!.commands,
                      DeviceCommand(
                        name: nameController.text,
                        command: commandController.text,
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    commandController.dispose();
    super.dispose();
  }
}
