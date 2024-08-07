import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:volt_vole/settings.dart';

class VoltageData {
  final int id;
  final double voltage;
  final DateTime timestamp;

  VoltageData(this.voltage, this.timestamp, {this.id = 0});

  factory VoltageData.fromJson(Map<String, dynamic> json) {
    return VoltageData(
      json['voltage'] as double,
      DateTime.parse(json['timestamp'] as String),
      id: json['id'] as int,
    );
  }

  factory VoltageData.fromRow(sqlite3.Row row) {
    return VoltageData(
      row['voltage'] as double,
      DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
      id: row['id'] as int,
    );
  }

  @override
  String toString() {
    return 'VoltageData{id: $id, voltage: $voltage, timestamp: $timestamp}';
  }

  Color getColor() {
    if(voltage >= Settings().yellowLowerBound && voltage <= Settings().yellowUpperBound) {
      return Colors.yellow;
    }
    if(voltage >= Settings().redLowerBound && voltage <= Settings().redUpperBound) {
      return Colors.red;
    }

    return Colors.green;
  }

  static List<VoltageData> randomData({int count = 100}) {
    var voltages = <VoltageData>[];
    var lastVoltage = 9.0;
    var random = Random();
    var randomStartTime = DateTime.now().subtract(Duration(hours: count));
    for (int i = 0; i < count; i++) {
      var change = (random.nextDouble() - 0.5) * 0.2;
      var newVoltage = (lastVoltage + change).clamp(9.0, 12.2);
      var randomHour = random.nextInt(24);
      var randomMinute = random.nextInt(60);
      var time = DateTime(
        randomStartTime.year,
        randomStartTime.month,
        randomStartTime.day,
        randomHour,
        randomMinute,
      ).add(Duration(hours: i));

      voltages.add(VoltageData(newVoltage, time));
      lastVoltage = newVoltage;
    }

    return voltages;
  }
}
