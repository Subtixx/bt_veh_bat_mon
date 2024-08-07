import 'dart:developer' as developer;
import 'package:logging/logging.dart';

class Log {
  static void log(String message,
      {int level = 0,
      String name = 'volt_vole',
      StackTrace? stackTrace,
      Object? error,
      String? stackCall}) {
    var now = DateTime.now();
    var format =
        '[${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}] ${'[]'.padRight(26, ' ')}\t$message';
    if (stackCall != null) {
      format =
          '[${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}] ${('[$stackCall]').padLeft(26, ' ')}\t$message';
    }
    developer.log(
      format,
      time: now,
      level: level,
      stackTrace: stackTrace,
      error: error,
      name: name,
    );
  }

  static void debug(String message,
      {String name = 'volt_vole', StackTrace? stackTrace, Object? error}) {
    log(
      message,
      level: Level.FINE.value,
      stackTrace: stackTrace,
      error: error,
      name: name,
      stackCall: getStackTraceMethod(StackTrace.current),
    );
  }

  static void error(String message,
      {String name = 'volt_vole', StackTrace? stackTrace, Object? error}) {
    log(
      message,
      level: Level.SEVERE.value,
      stackTrace: stackTrace,
      error: error,
      name: name,
      stackCall: getStackTraceMethod(StackTrace.current),
    );
  }

  static void info(String message,
      {String name = 'volt_vole', StackTrace? stackTrace, Object? error}) {
    log(
      message,
      level: Level.INFO.value,
      stackTrace: stackTrace,
      error: error,
      name: name,
      stackCall: getStackTraceMethod(StackTrace.current),
    );
  }

  static void warning(String message,
      {String name = 'volt_vole', StackTrace? stackTrace, Object? error}) {
    log(
      message,
      level: Level.WARNING.value,
      stackTrace: stackTrace,
      error: error,
      name: name,
      stackCall: getStackTraceMethod(StackTrace.current),
    );
  }

  static String getStackTraceMethod(StackTrace stackTrace) {
    var stackCall = stackTrace.toString().split('\n')[1];
    // #1      BatteryDevice.onScanResults (package:volt_vole/battery_device.dart:52:9):
    // We only care about "BatteryDevice.onScanResults" use regex to get the method name
    RegExp exp = RegExp(r'#\d+\s+.*\.(.*) \(.*\)');
    var result = exp.firstMatch(stackCall);
    return result!.group(1)!;
  }
}
