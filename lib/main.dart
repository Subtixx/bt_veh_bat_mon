import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volt_vole/database.dart';
import 'package:volt_vole/screens/device_screen.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:developer' as developer;

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'screens/device_selection_screen.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Connect to the Bluetooth device and read the voltage.
    double batteryVoltage = await readBatteryVoltage();

    // Write the voltage to a file.
    await writeVoltageToFile(batteryVoltage);

    // Check the voltage and show notification if too low.
    if (batteryVoltage < 11.5) {
      await showLowBatteryNotification(batteryVoltage);
    }

    return Future.value(true);
  });
}

Future<double> readBatteryVoltage() async {
  // Implement your Bluetooth connection and voltage reading logic here.
  return 11.0; // Placeholder for actual voltage reading
}

Future<void> writeVoltageToFile(double voltage) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/voltage_data.csv');

  final timestamp = DateTime.now().toIso8601String();
  final data = '$timestamp,$voltage\n';

  await file.writeAsString(data, mode: FileMode.append, flush: true);
}

Future<void> showLowBatteryNotification(double voltage) async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');
  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails('low_battery_channel', 'Low Battery',
          importance: Importance.max, priority: Priority.high, showWhen: false);
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(0, 'Low Battery Alert',
      'Current Voltage: $voltage V', platformChannelSpecifics);
}

void main() async {
  FlutterBluePlus.setLogLevel(LogLevel.none, color: true);
  WidgetsFlutterBinding.ensureInitialized();
  await Database("volt_vole.db").init();
  /*Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  Workmanager().registerPeriodicTask("1", "simplePeriodicTask",
      frequency: const Duration(minutes: 15));*/

  runApp(const MyApp());
}

class AppWidget extends StatefulWidget {
  const AppWidget({super.key});

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  String? _savedDeviceRemoteId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _savedDeviceRemoteId = prefs.getString('deviceRemoteId');
        if (_savedDeviceRemoteId != null) {
          developer.log('Saved device found: $_savedDeviceRemoteId');
        }
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    Database.instance.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    if(Database.instance.db == null) {
      Database.instance.init();
    }

    super.reassemble();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CircularProgressIndicator();
    } else if (_savedDeviceRemoteId == null) {
      return const DeviceSelectionScreen();
    } else {
      return DeviceScreen(_savedDeviceRemoteId!);
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VoltVole',
      theme: FlexThemeData.light(
        colors: const FlexSchemeColor(
          primary: Color(0xffbd93f9),
          primaryContainer: Color(0xff282a36),
          secondary: Color(0xffff79c6),
          secondaryContainer: Color(0xff44475a),
          tertiary: Color(0xffffb86c),
          tertiaryContainer: Color(0xff6272a4),
          appBarColor: Color(0xffbd93f9),
          error: Color(0xffff5555),
        ),
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 7,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 10,
          blendOnColors: false,
          useTextTheme: true,
          useM2StyleDividerInM3: true,
          alignedDropdown: true,
          useInputDecoratorThemeInDialogs: true,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        swapLegacyOnMaterial3: true,
        // To use the Playground font, add GoogleFonts package and uncomment
        // fontFamily: GoogleFonts.notoSans().fontFamily,
      ),
      darkTheme: FlexThemeData.dark(
        colors: const FlexSchemeColor(
          primary: Color(0xffbd93f9),
          primaryContainer: Color(0xff282a36),
          secondary: Color(0xffff79c6),
          secondaryContainer: Color(0xff44475a),
          tertiary: Color(0xffffb86c),
          tertiaryContainer: Color(0xff6272a4),
          appBarColor: Color(0xffbd93f9),
          error: Color(0xffff5555),
        ),
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 13,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 20,
          useTextTheme: true,
          useM2StyleDividerInM3: true,
          alignedDropdown: true,
          useInputDecoratorThemeInDialogs: true,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        swapLegacyOnMaterial3: true,
        // To use the Playground font, add GoogleFonts package and uncomment
        // fontFamily: GoogleFonts.notoSans().fontFamily,
      ),
      home: const AppWidget(),
    );
  }
}
