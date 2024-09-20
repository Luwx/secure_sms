import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:secure_sms/app_controller.dart';
import 'package:secure_sms/device_info.dart';
import 'package:secure_sms/home.dart';
import 'package:secure_sms/main.dart';
import 'package:secure_sms/utils.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({this.showDrawer = true, super.key});

  final bool showDrawer;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _appController = getIt<AppController>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _keyController = TextEditingController();

  final _configurationController = TextEditingController();

  var _showConfigurationTextField = false;

  Future<void> saveDevice(RemoteDevice device) async {
    final result = await _appController.saveDevice(device);
    if (!mounted) return;
    if (result case Left(:final value)) {
      showErrorToast(context, value);
    }

    await sendSMSCommand(
      context,
      'register',
      device,
      onSuccessMessage: 'Numero registrado',
    );

    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  final _mascaraTelefone = MaskTextInputFormatter(
    mask: '(##) ####-####',
    filter: {
      '#': RegExp('[0-9]'),
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Controle Seguro por SMS')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Cadastrar Dispositivo',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  const SizedBox(height: 16),
                  ListenableBuilder(
                    listenable: _phoneController,
                    builder: (context, child) {
                      if ((_phoneController.text.length) >= 15) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _phoneController.value = _mascaraTelefone.updateMask(
                            mask: '(##) #####-####',
                          );
                        });
                      }
                      if ((_phoneController.text.length) <= 14) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _phoneController.value = _mascaraTelefone.updateMask(
                            mask: '(##) ####-#####',
                          );
                        });
                      }
                      return TextFormField(
                        controller: _phoneController,
                        inputFormatters: [_mascaraTelefone],
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.phone),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text('* ', style: TextStyle(color: Colors.red)),
                              Text('Telefone'),
                            ],
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Campo obrigatório';
                          }
                          if (value.length < 14) {
                            return 'Telefone inválido';
                          }
                          return null;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _keyController,
                    maxLength: 16,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.lock),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text('* ', style: TextStyle(color: Colors.red)),
                          Text('Senha'),
                        ],
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      if (value.length != 16) {
                        return 'Senha deve ter 16 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final device = RemoteDevice(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          phoneNumber: _phoneController.text,
                          secretKey: _keyController.text,
                          name: _nameController.text.isNotEmpty
                              ? _nameController.text
                              : 'Dispositivo 1',
                          commandCounter: 0,
                          commands: const [],
                        );
                        saveDevice(device);
                      }
                    },
                    child: const Text('Continuar'),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Ou',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (!_showConfigurationTextField) {
                        setState(() {
                          _showConfigurationTextField = true;
                        });
                        return;
                      }
                      final configuration = _configurationController.text;
                      if (configuration.isNotEmpty) {
                        try {
                          final device = RemoteDevice.fromMap(
                            json.decode(configuration) as Map<String, dynamic>,
                          );
                          await saveDevice(device);
                        } catch (e, stack) {
                          debugPrint(e.toString());
                          debugPrintStack(stackTrace: stack);
                          if (context.mounted) {
                            showErrorToast(context, 'Configuração inválida');
                          }
                        }
                      }
                    },
                    label: Text(
                      _showConfigurationTextField
                          ? 'Continuar'
                          : 'Colar Configuração',
                    ),
                    icon: Icon(
                      _showConfigurationTextField ? Icons.send : Icons.paste,
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _showConfigurationTextField
                        ? Column(
                            children: [
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _configurationController,
                                maxLines: 5,
                                decoration: const InputDecoration(
                                  labelText: 'Configuração',
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
