import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:volt_vole/battery_device.dart';
import 'package:volt_vole/database.dart';
import 'package:volt_vole/logging.dart';
import 'package:volt_vole/settings.dart';
import 'package:volt_vole/voltage_data.dart';
import 'package:volt_vole/widgets/chart_widget.dart';
import 'package:volt_vole/widgets/data_table_widget.dart';
import 'package:volt_vole/widgets/stat_widget.dart';

class GraphWidget extends StatefulWidget {
  final BatteryDevice batteryDevice;

  const GraphWidget(this.batteryDevice, {super.key});

  @override
  State<GraphWidget> createState() => _GraphWidgetState();
}

class _GraphWidgetState extends State<GraphWidget> {
  late BatteryDevice _batteryDevice;
  List<VoltageData> _voltages = [];
  VoltageData? _lowestVoltage;
  VoltageData? _highestVoltage;
  VoltageData? _lastVoltage;

  bool _isSortAscending = false;
  bool _isShowAll = false;

  bool _showDateFilter = false;

  @override
  void initState() {
    super.initState();

    _batteryDevice = widget.batteryDevice;
    _voltages = _batteryDevice.voltages;
    executeSort();
    _batteryDevice.onBatteryValueAdded = (value) {
      onVoltagesUpdated(value);
    };
  }

  @override
  void dispose() {
    _batteryDevice.dispose();
    super.dispose();
  }

  // On re-display
  @override
  void didUpdateWidget(covariant GraphWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    Log.debug('didUpdateWidget', name: runtimeType.toString());
    onRefresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Log.debug('didChangeDependencies', name: runtimeType.toString());
  }

  @override
  void reassemble() {
    super.reassemble();
    Log.debug('reassemble', name: runtimeType.toString());
    onRefresh();
  }

  void onRefresh() {
    _batteryDevice.onRefresh();
    _voltages = _batteryDevice.voltages;
    executeSort();
  }

  void onVoltagesUpdated(double value) {
    Database.instance.insert(VoltageData(value, DateTime.now()));
    setState(() {
      _voltages = _batteryDevice.voltages;
      executeSort();
    });
  }

  void executeSort() {
    _voltages.sort((a, b) => _isSortAscending
        ? a.timestamp.compareTo(b.timestamp)
        : b.timestamp.compareTo(a.timestamp));
    if (_voltages.isEmpty) {
      _lowestVoltage = null;
      _highestVoltage = null;
      _lastVoltage = null;
      return;
    }

    _lowestVoltage = _voltages.reduce((a, b) => a.voltage < b.voltage ? a : b);
    _highestVoltage = _voltages.reduce((a, b) => a.voltage > b.voltage ? a : b);
    _lastVoltage = _voltages.reduce((a, b) =>
        a.timestamp.millisecondsSinceEpoch > b.timestamp.millisecondsSinceEpoch
            ? a
            : b);

    if (_isShowAll) {
      return;
    }
  }

  // For the chart we want to display only non-duplicated voltages and only the last 50.
  /*List<VoltageData> getChartData() {
    final seenTimestamps = <int>{};
    return _voltages.where((voltageData) {
      final timestamp = voltageData.timestamp.millisecondsSinceEpoch;
      if (seenTimestamps.contains(timestamp)) {
        return false;
      } else {
        seenTimestamps.add(timestamp);
        return true;
      }
    }).toList();
  }*/

  // Based on Settings().dayFilter reduce the resolution. E.g. 7 days -> only every 12 hours are shown
  List<VoltageData> getChartData() {
    if (Settings().dayFilter == 0) {
      return _voltages;
    } else {
      final Map<int, VoltageData> filteredData = {};
      final int interval = _getInterval(Settings().dayFilter);

      for (var voltageData in _voltages) {
        final int key =
            voltageData.timestamp.millisecondsSinceEpoch ~/ interval;
        if (!filteredData.containsKey(key)) {
          filteredData[key] = voltageData;
        }
      }

      var result = filteredData.values.toList();

      // Ensure at least 2 data points
      if (result.length < 2 && _voltages.isNotEmpty) {
        if (!result.contains(_voltages.first)) {
          result.insert(0, _voltages.first);
        }
        if (!result.contains(_voltages.last)) {
          result.add(_voltages.last);
        }
      }

      Log.debug('filteredData: $filteredData');
      return result;
    }
  }

  int _getInterval(int dayFilter) {
    switch (dayFilter) {
      case 1:
        return Duration.millisecondsPerHour; // 1 hour
      case 24:
        return Duration.millisecondsPerDay; // 24 hours
      case 7:
        return 7 * Duration.millisecondsPerDay; // 7 days
      case 30:
        return 30 * Duration.millisecondsPerDay; // 30 days
      case 90:
        return 90 * Duration.millisecondsPerDay; // 90 days
      case 365:
        return 365 * Duration.millisecondsPerDay; // 365 days
      default:
        return Duration.millisecondsPerHour; // Default to 1 hour
    }
  }

  @override
  Widget build(BuildContext context) {
    var chartData = getChartData();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                StatWidget(
                    mainColor: _highestVoltage?.getColor(),
                    label: 'Max Voltage',
                    time: _highestVoltage?.timestamp,
                    value: _highestVoltage == null
                        ? 'N/A'
                        : '${_highestVoltage!.voltage.toStringAsFixed(2)}V'),
                StatWidget(
                  mainColor: _lastVoltage?.getColor(),
                  label: 'Last Voltage',
                  time: _lastVoltage?.timestamp,
                  value: _voltages.isEmpty
                      ? 'N/A'
                      : '${_lastVoltage!.voltage.toStringAsFixed(2)}V',
                ),
                StatWidget(
                    mainColor: _lowestVoltage?.getColor(),
                    label: 'Min Voltage',
                    time: _lowestVoltage?.timestamp,
                    value: _lowestVoltage == null
                        ? 'N/A'
                        : '${_lowestVoltage!.voltage.toStringAsFixed(2)}V'),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: ChartWidget(chartData),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      border: Border.all(
                          color:
                              Theme.of(context).colorScheme.primaryContainer),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8.0),
                    child: const Text('Date'),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      border: Border.all(
                          color:
                              Theme.of(context).colorScheme.primaryContainer),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8.0),
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: const Text('Time'),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      border: Border.all(
                          color:
                              Theme.of(context).colorScheme.primaryContainer),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8.0),
                    child: const Text('Voltage'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: DataTableWidget(chartData),
            ),
          ),
        ],
      ),
    );
  }
}
