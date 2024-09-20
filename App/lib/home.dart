import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sms_actual_kotlin/flutter_sms.dart';
// import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
// import 'package:flutter_sms/flutter_sms.dart';
import 'package:fpdart/fpdart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:secure_sms/app_controller.dart';
import 'package:secure_sms/device_info.dart';
import 'package:secure_sms/main.dart';
import 'package:secure_sms/message_list.dart';
import 'package:secure_sms/setup_screen.dart';
import 'package:secure_sms/shared_widgets/add_command_dialog.dart';
import 'package:secure_sms/shared_widgets/app_drawer.dart';
import 'package:secure_sms/shared_widgets/loading_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appController = getIt<AppController>();
    return ListenableBuilder(
      listenable: appController,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              appController.devices.length == 1
                  ? appController.devices.first.name
                  : 'Meu Controle',
            ),
            actions: [
              if (appController.devices.length == 1)
                _buildPopUpDevice(context, appController.devices.first),
              Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.sms),
                    onPressed: () {
                      Scaffold.of(context).openEndDrawer();
                    },
                  );
                },
              ),
            ],
          ),
          drawer:
              const AppDrawer(selectedDestination: AppDrawerDestination.home),
          endDrawer: const MessageListDrawer(),
          body: appController.devices.length == 1
              ? appController.devices.first.commands.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Sem comandos',
                            style: TextStyle(
                              fontSize: 24,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () async {
                              final result = await showDialog<RemoteDevice>(
                                context: context,
                                builder: (context) => AddCommandDialog(
                                  devices: appController.devices,
                                  initialDevice: appController.devices.first,
                                ),
                              );
                              if (result != null) {
                                await appController.updateDevice(result);
                              }
                            },
                            label: const Text('Adicionar comando'),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.center,
                      child: _buildCommandGrid(
                        context,
                        appController.devices.first,
                      ),
                    )
              : ListView.builder(
                  itemCount: appController.devices.length,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  itemBuilder: (context, index) {
                    final device = appController.devices[index];

                    return Card(
                      surfaceTintColor: Theme.of(context).colorScheme.primary,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          bottom: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  device.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                _buildPopUpDevice(context, device),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (device.commands.isEmpty)
                              SizedBox(
                                width: double.infinity,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Sem comandos',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () async {
                                        final result =
                                            await showDialog<RemoteDevice>(
                                          context: context,
                                          builder: (context) =>
                                              AddCommandDialog(
                                            devices: appController.devices,
                                            initialDevice: device,
                                          ),
                                        );
                                        if (result != null) {
                                          await appController
                                              .updateDevice(result);
                                        }
                                      },
                                      label: const Text('Adicionar comando'),
                                      icon: const Icon(Icons.add),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: _buildCommandGrid(context, device),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildCommandGrid(BuildContext context, RemoteDevice device) {
    final appController = getIt<AppController>();
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: device.commands.length == 1 ? 1 : 2,
      shrinkWrap: true,
      childAspectRatio: 1.5,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: device.commands
          .map(
            (command) => ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(command.name),
              onPressed: () => sendSMSCommand(
                context,
                command.command,
                device,
              ),
              onLongPress: () {
                // show bottom sheet with options to edit or delete command
                showModalBottomSheet<void>(
                  context: context,
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            command.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.terminal),
                          title: Text('Comando: ${command.command}'),
                          // subtitle: Text(command.command),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () async {
                            // show confirmation dialog
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Deletar comando'),
                                content: const Text(
                                  'Tem certeza que deseja deletar este comando?',
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(
                                      false,
                                    ),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: Text(
                                      'Deletar',
                                      style: TextStyle(
                                        color:
                                            Theme.of(context).colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed ?? false) {
                              device.commands.remove(command);
                              await appController.updateDevice(device);
                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                            }
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              Theme.of(context).colorScheme.error,
                            ),
                            foregroundColor: WidgetStateProperty.all(
                              Theme.of(context).colorScheme.onError,
                            ),
                          ),
                          label: const Text('Deletar'),
                          icon: const Icon(Icons.delete_forever),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
          .toList(),
    );
  }

  Widget _buildPopUpDevice(BuildContext context, RemoteDevice device) {
    final appController = getIt<AppController>();
    return PopupMenuButton(
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            value: 'edit',
            onTap: () async {
              final result = await showDialog<RemoteDevice>(
                context: context,
                builder: (context) => AddCommandDialog(
                  devices: appController.devices,
                  initialDevice: device,
                ),
              );
              if (result != null) {
                await appController.updateDevice(result);
              }
            },
            child: const Text('Adicionar comando'),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Text(
              'Excluir dispositivo',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            onTap: () async {
              // show confirmation dialog
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text(
                    'Deletar dispositivo',
                  ),
                  content: const Text(
                    'Tem certeza que deseja deletar este dispositivo?',
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(
                        false,
                      ),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        'Deletar',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              if (result ?? false) {
                await appController.deleteDevice(device);
                if (!context.mounted) return;

                if (appController.devices.isEmpty) {
                  await Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (context) => const SetupScreen(
                        showDrawer: false,
                      ),
                    ),
                  );
                } else {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
        ];
      },
    );
  }
}

Future<void> sendSMSCommand(
  BuildContext context,
  String command,
  RemoteDevice device, {
  String onSuccessMessage = 'Comando enviado com sucesso',
}) async {
  final canSendSMS = await Permission.sms.request();

  if (!canSendSMS.isGranted && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
        content: const Text('Permissão para enviar SMS negada'),
      ),
    );
    return;
  }

  TaskEither<Object, Unit> task() {
    return TaskEither<Object, Unit>.tryCatch(
      () async {
        final encryptedCommand = await encryptCommand(
          '${device.commandCounter}|$command',
          device.secretKey,
        );

        await sendSMS(
          message: encryptedCommand,
          recipients: [device.phoneNumber],
          sendDirect: true,
        );

        // increment command counter
        final appController = getIt<AppController>();
        await appController.updateDevice(
          device.copyWith(commandCounter: device.commandCounter + 1),
        );

        return unit;
      },
      (e, stack) {
        debugPrint('Error sending SMS: $e, stack: $stack');
        return e;
      },
    );
  }

  if (context.mounted) {
    final result = await LoadingDialog.showLoadingDialog(
      context,
      task,
      'Enviando comando',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: (result?.isLeft() ?? false)
              ? Theme.of(context).colorScheme.error
              : null,
          content: Text(
            switch (result) {
              Right() => onSuccessMessage,
              Left() || null => 'Falha ao enviar comando',
            },
          ),
        ),
      );
    }
  }
}

Future<String> encryptCommand(String command, String key) async {
  final algorithm = AesGcm.with128bits();
  final secretKey = SecretKey(utf8.encode(key.padRight(16).substring(0, 16)));
  final nonce = algorithm.newNonce();

  final secretBox = await algorithm.encrypt(
    utf8.encode(command),
    secretKey: secretKey,
    nonce: nonce,
  );

  final combined = Uint8List.fromList([
    ...secretBox.nonce,
    ...secretBox.cipherText,
    ...secretBox.mac.bytes,
  ]);

  return base64Encode(combined);
}
