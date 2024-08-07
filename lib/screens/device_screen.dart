import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:volt_vole/battery_device.dart';
import 'dart:developer' as developer;

import 'package:volt_vole/custom_bluetooth_device.dart';
import 'package:volt_vole/screens/settings_screen.dart';
import 'package:volt_vole/widgets/graph_widget.dart';

import 'device_selection_screen.dart';

class DeviceScreen extends StatefulWidget {
  final String deviceRemoteId;

  const DeviceScreen(this.deviceRemoteId, {super.key}) : super();

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  late BatteryDevice _batteryDevice;

  @override
  void initState() {
    super.initState();

    _batteryDevice = BatteryDevice(widget.deviceRemoteId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_batteryDevice.name} (${_batteryDevice.idString})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              ).then(
                (value) {
                  setState(() {
                    _batteryDevice.onRefresh();
                  });
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _batteryDevice.onRefresh();
              });
            },
          ),
        ],
      ),
      body: GraphWidget(_batteryDevice),
    );
  }
}
