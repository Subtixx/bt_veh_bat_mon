import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:volt_vole/custom_bluetooth_device.dart';
import 'device_screen.dart';
import 'settings_screen.dart';

class DeviceSelectionScreen extends StatefulWidget {
  const DeviceSelectionScreen({super.key});

  @override
  State<DeviceSelectionScreen> createState() => _DeviceSelectionScreenState();
}

class _DeviceSelectionScreenState extends State<DeviceSelectionScreen> {
  final List<CustomBluetoothDevice> _devices =
      List<CustomBluetoothDevice>.empty(growable: true);
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  bool _isScanning = false;
  bool _hasScanned = false;

  bool _showAllDevices = true;
  bool _showUnknownDevices = true;
  bool _stopAfterDeviceFound = true;

  @override
  void initState() {
    super.initState();

    _scanResultsSubscription =
        FlutterBluePlus.scanResults.listen(processScanResult);
    _isScanningSubscription =
        FlutterBluePlus.isScanning.listen(onIsScanningChanged);

    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showAllDevices = prefs.getBool('showAllDevices') ?? true;
      _showUnknownDevices = prefs.getBool('showUnknownDevices') ?? true;
      _stopAfterDeviceFound = prefs.getBool('stopAfterDeviceFound') ?? true;
    });
  }

  void onIsScanningChanged(bool state) {
    _isScanning = state;
    _hasScanned = true;
    if (mounted) {
      setState(() {});
    }
  }

  // On navigating back
  @override
  void didUpdateWidget(covariant DeviceSelectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSettings();
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Device'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: onSettingsPressed,
          ),
        ],
      ),
      body: RefreshIndicator(
        notificationPredicate: (notification) => !_isScanning,
        onRefresh: _scan,
        child: ListView(
          children: <Widget>[
            _isScanning ? const LinearProgressIndicator() : Container(),
            scanListTopBar(),
            ..._buildListTiles(),
          ],
        ),
      ),
      floatingActionButton: _isScanning
          ? FloatingActionButton(
              child: const Icon(Icons.stop),
              onPressed: () {
                FlutterBluePlus.stopScan();
              },
            )
          : FloatingActionButton(
              child: const Icon(Icons.refresh),
              onPressed: () {
                _scan();
              },
            ),
    );
  }

  Widget scanListTopBar() {
    if (_isScanning) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: const Center(
          child: Text('Scanning for devices...'),
        ),
      );
    }

    if (_devices.isEmpty && _hasScanned) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: const Center(
          child: Text('No devices found.'),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  List<Widget> _buildListTiles() {
    return _devices
        .where((device) => _deviceCheck(device))
        .map((device) => _buildListTile(device))
        .toList();
  }

  ListTile _buildListTile(CustomBluetoothDevice device) {
    return ListTile(
      title: Text(device.name),
      subtitle: Text(device.id),
      leading: const Icon(Icons.bluetooth_connected),
      tileColor: device.isCorrectDevice()
          ? Theme.of(context).colorScheme.primary
          : null,
      textColor: device.isCorrectDevice()
          ? Theme.of(context).colorScheme.onPrimary
          : null,
      iconColor: device.isCorrectDevice()
          ? Theme.of(context).colorScheme.onPrimary
          : null,
      onTap: () {
        _connectAndNavigateAway(device);
      },
    );
  }

  void _connectAndNavigateAway(CustomBluetoothDevice device) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('deviceRemoteId', device.id);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DeviceScreen(device.id),
        ),
      );
    });
  }

  Future<void> _scan() async {
    _devices.clear();
    try {
      await FlutterBluePlus.startScan(
          //withRemoteIds: ["00:00:00:D1:0A:84"],
          //withNames: ["Battery Asst"],
          timeout: const Duration(seconds: 15));
    } catch (e) {
      if (mounted) {
        // Show snackbar
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                "An error occurred while scanning for devices. Please try again.")));
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  void processScanResult(List<ScanResult> results) async {
    if (!mounted) {
      return;
    }
    setState(() {
      var devices = results
          .map((result) => CustomBluetoothDevice(device: result.device))
          .toList();

      if (_stopAfterDeviceFound &&
          devices.where((device) => device.isCorrectDevice()).isNotEmpty) {
        FlutterBluePlus.stopScan();
      }

      devices.sort((a, b) {
        if (a.isCorrectDevice() && !b.isCorrectDevice()) {
          return -1;
        }
        if (!a.isCorrectDevice() && b.isCorrectDevice()) {
          return 1;
        }
        return a.name.compareTo(b.name);
      });
      _devices.clear();
      _devices.addAll(devices);
    });
  }

  bool _deviceCheck(CustomBluetoothDevice device) {
    if (device.isUnknownDevice() && !_showUnknownDevices) {
      return false;
    }

    if (_showAllDevices) {
      return true;
    }
    if (!device.isCorrectDevice()) {
      return false;
    }

    return true;
  }

  void onSettingsPressed() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return const SettingsScreen();
    }));

    _loadSettings();
  }
}
