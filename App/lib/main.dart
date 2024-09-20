// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:realm/realm.dart';
import 'package:secure_sms/app_controller.dart';
import 'package:secure_sms/home.dart';
import 'package:secure_sms/realm/realm_device_repository.dart';
import 'package:secure_sms/realm/realm_remote_device.dart';

import 'package:secure_sms/setup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  await getIt.allReady();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appController = getIt<AppController>();
    return MaterialApp(
      title: 'Arduino Control',
      home: appController.devices.isNotEmpty
          ? const HomeScreen()
          : const SetupScreen(
              showDrawer: false,
            ),
      theme: FlexThemeData.light(
        scheme: FlexScheme.indigo,
        usedColors: 1,
        surfaceMode: FlexSurfaceMode.highBackgroundLowScaffold,
        blendLevel: 7,
        appBarStyle: FlexAppBarStyle.background,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 8,
          blendOnColors: false,
          useTextTheme: true,
          useM2StyleDividerInM3: true,
          elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
          elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
          segmentedButtonSchemeColor: SchemeColor.primary,
          inputDecoratorSchemeColor: SchemeColor.primary,
          inputDecoratorBackgroundAlpha: 21,
          inputDecoratorRadius: 8,
          inputDecoratorUnfocusedHasBorder: false,
          inputDecoratorPrefixIconSchemeColor: SchemeColor.primary,
          popupMenuRadius: 6,
          popupMenuElevation: 4,
          alignedDropdown: true,
          dialogElevation: 3,
          dialogRadius: 20,
          useInputDecoratorThemeInDialogs: true,
          drawerIndicatorSchemeColor: SchemeColor.primary,
          bottomNavigationBarMutedUnselectedLabel: false,
          bottomNavigationBarMutedUnselectedIcon: false,
          menuRadius: 6,
          menuElevation: 4,
          menuBarRadius: 0,
          menuBarElevation: 1,
          navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
          navigationBarMutedUnselectedLabel: false,
          navigationBarSelectedIconSchemeColor: SchemeColor.onPrimary,
          navigationBarMutedUnselectedIcon: false,
          navigationBarIndicatorSchemeColor: SchemeColor.primary,
          navigationBarIndicatorOpacity: 1,
          navigationBarBackgroundSchemeColor: SchemeColor.background,
          navigationBarElevation: 0,
          navigationRailSelectedLabelSchemeColor: SchemeColor.primary,
          navigationRailMutedUnselectedLabel: false,
          navigationRailSelectedIconSchemeColor: SchemeColor.onPrimary,
          navigationRailMutedUnselectedIcon: false,
          navigationRailIndicatorSchemeColor: SchemeColor.primary,
          navigationRailIndicatorOpacity: 1,
          appBarBackgroundSchemeColor: SchemeColor.primary,
        ),
        keyColors: const FlexKeyColors(
          useTertiary: true,
          keepPrimary: true,
        ),
        tones: FlexTones.vivid(Brightness.light),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
      ),
      darkTheme: FlexThemeData.dark(
        scheme: FlexScheme.indigo,
        usedColors: 1,
        surfaceMode: FlexSurfaceMode.highBackgroundLowScaffold,
        blendLevel: 4,
        appBarStyle: FlexAppBarStyle.background,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 10,
          blendTextTheme: true,
          useTextTheme: true,
          useM2StyleDividerInM3: true,
          elevatedButtonSchemeColor: SchemeColor.onPrimaryContainer,
          elevatedButtonSecondarySchemeColor: SchemeColor.primaryContainer,
          segmentedButtonSchemeColor: SchemeColor.primary,
          inputDecoratorSchemeColor: SchemeColor.primary,
          inputDecoratorBackgroundAlpha: 43,
          inputDecoratorRadius: 8,
          inputDecoratorUnfocusedHasBorder: false,
          inputDecoratorPrefixIconSchemeColor: SchemeColor.primary,
          popupMenuRadius: 6,
          popupMenuElevation: 4,
          alignedDropdown: true,
          dialogElevation: 3,
          dialogRadius: 20,
          useInputDecoratorThemeInDialogs: true,
          drawerIndicatorSchemeColor: SchemeColor.primary,
          bottomNavigationBarMutedUnselectedLabel: false,
          bottomNavigationBarMutedUnselectedIcon: false,
          menuRadius: 6,
          menuElevation: 4,
          menuBarRadius: 0,
          menuBarElevation: 1,
          navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
          navigationBarMutedUnselectedLabel: false,
          navigationBarSelectedIconSchemeColor: SchemeColor.onPrimary,
          navigationBarMutedUnselectedIcon: false,
          navigationBarIndicatorSchemeColor: SchemeColor.primary,
          navigationBarIndicatorOpacity: 1,
          navigationBarBackgroundSchemeColor: SchemeColor.background,
          navigationBarElevation: 0,
          navigationRailSelectedLabelSchemeColor: SchemeColor.primary,
          navigationRailMutedUnselectedLabel: false,
          navigationRailSelectedIconSchemeColor: SchemeColor.onPrimary,
          navigationRailMutedUnselectedIcon: false,
          navigationRailIndicatorSchemeColor: SchemeColor.primary,
          navigationRailIndicatorOpacity: 1,
        ),
        keyColors: const FlexKeyColors(
          useTertiary: true,
        ),
        tones: FlexTones.vivid(Brightness.dark),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
      ),
    );
  }
}

final getIt = GetIt.instance;

void setupDependencies() {
  getIt
    ..registerSingleton(
      RemoteDeviceRepository(
        realm: Realm(
          Configuration.local([
            RealmRemoteDevice.schema,
            RealmDeviceCommand.schema,
          ]),
        ),
      ),
    )
    ..registerSingletonAsync(() async {
      final controller = AppController(storage: getIt());
      await controller.init();
      return controller;
    });
}

Future<String> encrypt(String keyStr, String plaintextStr) async {
  print('Encryption Key: $keyStr');
  print('Plaintext: $plaintextStr');

  final message = utf8.encode(plaintextStr);
  final key = utf8.encode(keyStr.padRight(16).substring(0, 16));

  print('Key: $key, Hex: ${_bytesToHex(key)}, Base64: ${base64Encode(key)}');

  final algorithm = AesGcm.with128bits();
  final secretKey = SecretKey(key);
  final nonce = AesGcm.with128bits().newNonce();

  // Encrypt
  final secretBox = await algorithm.encrypt(
    message,
    secretKey: secretKey,
    nonce: nonce,
  );

  print('Nonce: ${secretBox.nonce}, '
      'Hex: ${_bytesToHex(Uint8List.fromList(secretBox.nonce))}, '
      'Base64: ${base64Encode(Uint8List.fromList(secretBox.nonce))}');
  print('Ciphertext: ${secretBox.cipherText}, '
      'Hex: ${_bytesToHex(Uint8List.fromList(secretBox.cipherText))}, '
      'Base64: ${base64Encode(Uint8List.fromList(secretBox.cipherText))}');
  print('MAC: ${secretBox.mac.bytes}, '
      'Hex: ${_bytesToHex(Uint8List.fromList(secretBox.mac.bytes))}, '
      'Base64: ${base64Encode(Uint8List.fromList(secretBox.mac.bytes))}');

  // Combine nonce, ciphertext, and MAC
  final combined = Uint8List.fromList([
    ...secretBox.nonce,
    ...secretBox.cipherText,
    ...secretBox.mac.bytes,
  ]);

  final base64Output = base64Encode(combined);
  print('Base64 Output: $base64Output');

  return base64Output;
}

Future<String?> decrypt(String keyStr, String base64Input) async {
  print('Decryption Key: $keyStr');
  print('Base64 Input: $base64Input');

  if (base64Input.contains('ckQ1')) {
    print(base64Input);
  }

  try {
    final combined = base64Decode(base64Input.trim());

    final nonce = combined.sublist(0, 12);
    final cipherText = combined.sublist(12, combined.length - 16);
    final mac = combined.sublist(combined.length - 16);

    print('Nonce: $nonce, Hex: ${_bytesToHex(nonce)}, '
        'Base64: ${base64Encode(nonce)}');
    print(
      'Ciphertext: $cipherText, Hex: ${_bytesToHex(cipherText)}, '
      'Base64: ${base64Encode(cipherText)}',
    );
    print('MAC: $mac, Hex: ${_bytesToHex(mac)}, Base64: ${base64Encode(mac)}');

    final key = utf8.encode(keyStr.padRight(16).substring(0, 16));
    final algorithm = AesGcm.with128bits();
    final secretKey = SecretKey(key);

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(mac),
    );

    final clearText = await algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    final decryptedText = utf8.decode(clearText);
    print('Decrypted Text: $decryptedText');
    return decryptedText;
  } catch (e) {
    return null;
  }
}

String _bytesToHex(List<int> bytes) {
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(' ');
}
