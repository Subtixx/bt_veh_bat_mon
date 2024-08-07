import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class CustomBluetoothDevice {
  final BluetoothDevice device;

  CustomBluetoothDevice({
    required this.device,
  });

  String get name =>
      device.platformName.isNotEmpty ? device.platformName : "Unnamed Device";

  String get id => device.remoteId.toString();

  bool isUnknownDevice() {
    return name == "Unnamed Device";
  }

  bool isCorrectDevice() {
    return id == "00:00:00:D1:0A:84" || name == "Battery Asst";
  }
}
