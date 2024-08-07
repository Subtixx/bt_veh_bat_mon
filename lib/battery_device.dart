import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:volt_vole/logging.dart';
import 'package:volt_vole/utils.dart';
import 'package:volt_vole/voltage_data.dart';

import 'database.dart';

class BatteryDevice {
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;
  late StreamSubscription<List<int>> _valueSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;

  final List<VoltageData> _voltages = <VoltageData>[];

  BluetoothDevice? _device;
  BluetoothService? _batteryService;
  BluetoothCharacteristic? _batteryCharacteristic;
  bool _isScanning = false;

  Function(double) onBatteryValueAdded = (double batteryValue) {};

  final String id;

  String get idString => _device != null
      ? MacAddressUtils.getCollapsedMacAddress(_device!.remoteId.toString())
      : 'Unknown';

  String get name => _device?.platformName ?? 'Unknown';

  BatteryDevice(this.id) {
    onRefresh();

    _scanResultsSubscription =
        FlutterBluePlus.scanResults.listen(onScanResults);
    _isScanningSubscription =
        FlutterBluePlus.isScanning.listen(onIsScanningChanged);
    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 5),
      withRemoteIds: [id],
    );
  }

  void onRefresh() {
    _voltages.clear();
    for (var voltage in Database.instance.voltages) {
      _voltages.add(voltage);
    }
  }

  void dispose() {
    _valueSubscription.cancel();
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    _connectionStateSubscription?.cancel();
  }

  void onScanResults(List<ScanResult> results) async {
    if (!_isScanning) {
      Log.debug('Not currently scanning, skipping',
          name: runtimeType.toString());
      return;
    }

    var deviceResult = results
        .where((result) => result.device.remoteId.toString() == id)
        .firstOrNull;
    if (deviceResult == null) {
      Log.debug('Device not found, skipping', name: runtimeType.toString());
      return;
    }

    _device = deviceResult.device;
    Log.debug('Found device: ${_device!}', name: runtimeType.toString());

    _connectionStateSubscription =
        _device!.connectionState.listen(onConnectionStateChange);
    _device!.connect();
  }

  void onIsScanningChanged(bool isScanning) {
    _isScanning = isScanning;
    if (!_isScanning) {
      _device?.disconnect();
    }
  }

  void onConnectionStateChange(BluetoothConnectionState state) {
    if (_device == null) {
      Log.debug('No device connected..', name: runtimeType.toString());
      return;
    }

    if (state == BluetoothConnectionState.connected) {
      Log.debug('Connected', name: runtimeType.toString());
      _device!.discoverServices().then(onServicesDiscovered);
    } else if (state == BluetoothConnectionState.disconnected) {
      Log.debug('Disconnected: ${_device!.disconnectReason ?? 'Unknown'}',
          name: runtimeType.toString());
    }
  }

  void onServicesDiscovered(List<BluetoothService> services) {
    Log.debug('${services.length} Services discovered: $services',
        name: runtimeType.toString());

    _batteryService = services
        .where((service) => service.characteristics
            .where((characteristic) => characteristic.uuid.toString() == 'ae02')
            .isNotEmpty)
        .firstOrNull;

    if (_batteryService == null) {
      Log.debug('No Battery Service found', name: runtimeType.toString());
      return;
    }

    _batteryCharacteristic = _batteryService!.characteristics
        .where((characteristic) => characteristic.uuid.toString() == 'ae02')
        .firstOrNull;
    if (_batteryCharacteristic == null) {
      Log.debug('No Battery Characteristic found',
          name: runtimeType.toString());
      return;
    }

    _batteryCharacteristic!.setNotifyValue(true);
    _valueSubscription = _batteryCharacteristic!.onValueReceived.listen(onBatteryValueReceived);
  }

  void onBatteryValueReceived(List<int> value) {
    var hexValues = value
        .map((byte) =>
            "0x${byte.toRadixString(16).padLeft(2, '0').toUpperCase()}")
        .toList();
    var hex = hexValues.join(", ");
    Log.debug('Received Values: $hex', name: runtimeType.toString());
    if (value[0] != 170) {
      Log.debug('Invalid first byte: ${hexValues[0]}',
          name: runtimeType.toString());
      return;
    }
    if (value[1] != 2) {
      Log.debug('Invalid second byte: ${hexValues[1]}',
          name: runtimeType.toString());
      return;
    }

    // 170, 2, 100, 85 = 10
    //    0x02, 0x64 0x55
    // XXX, 612 / 62 = 10
    // 170, 2, 166, 85 = 11

    // 170, 2, 231, 85 = 12

    // 8 byte int from 3 bytes
    var voltageInt = (value[1] << 8) | value[2];
    var voltage = voltageInt / 62;
    _voltages.add(VoltageData(voltage, DateTime.now()));
    onBatteryValueAdded(voltage);

    Log.debug('Voltage: $voltage', name: runtimeType.toString());
  }

  List<VoltageData> get voltages => _voltages;
}
