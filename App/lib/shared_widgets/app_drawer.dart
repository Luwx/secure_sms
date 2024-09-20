import 'package:flutter/material.dart';
import 'package:secure_sms/device_list_screen.dart';
import 'package:secure_sms/home.dart';
import 'package:secure_sms/setup_screen.dart';

enum AppDrawerDestination {
  home,
  registerDevice,
  devices,
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({required this.selectedDestination, super.key});

  final AppDrawerDestination selectedDestination;

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      onDestinationSelected: (destination) {
        final drawerDestination = AppDrawerDestination.values[destination];
        switch (drawerDestination) {
          case AppDrawerDestination.home:
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (context) => const HomeScreen(),
              ),
            );
          case AppDrawerDestination.registerDevice:
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const SetupScreen(),
              ),
            );
          case AppDrawerDestination.devices:
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (context) => const DeviceListScreen(),
              ),
            );
        }
      },
      selectedIndex: selectedDestination.index,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
          child: Text(
            'Controle Seguro por SMS',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const NavigationDrawerDestination(
          label: Text('Home'),
          icon: Icon(Icons.home),
        ),
        const NavigationDrawerDestination(
          label: Text('Cadastrar Dispositivo'),
          icon: Icon(Icons.on_device_training),
        ),
        // const NavigationDrawerDestination(
        //   label: Text('Dispositivos'),
        //   icon: Icon(Icons.devices),
        // ),
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
          child: Divider(),
        ),
      ],
    );
  }
}
