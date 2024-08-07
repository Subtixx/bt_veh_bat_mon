import 'dart:math';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class _Data {
  _Data(this.time, this.voltage);

  final DateTime time;
  final double voltage;
}

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

/*
The main graph screen should have a graph on top and below controls to set the time range for the graph.
Below that, there should be table of data with the same time range as the graph.
*/
class _GraphScreenState extends State<GraphScreen> {
  late List<_Data> chartData = [];
  // Region limits
  final double _yellowLowerBound = 9;
  final double _yellowUpperBound = 10;
  final double _redLowerBound = 8;
  final double _redUpperBound = 9;
  final double _blackLowerBound = 0;
  final double _blackUpperBound = 8;

  int _timeRange = 10;
  double _voltageUpperBound = 20.0;
  double _voltageLowerBound = 0.0;

  List<_Data> _data = [];

  @override
  void initState() {
    super.initState();

    var lastVoltage = 9.0;
    for (int i = 0; i < 100; i++) {
      var voltage = lastVoltage + Random().nextDouble() - 0.5;
      lastVoltage = voltage;
      chartData
          .add(_Data(DateTime.now().add(Duration(seconds: i)), voltage));
    }

    _data = _getData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // line chart using syncfusion_flutter_charts. X = time, Y = voltage
    return Scaffold(
      appBar: AppBar(
        title: const Text('Graph Screen'),
      ),
      body: Column(
        children: [
          _buildGraph(),
          _buildDataTable(),
        ],
      ),
    );
  }

  List<_Data> _getData() {
    var now = DateTime.now();
    return chartData
        .where((data) => now.difference(data.time).inSeconds < _timeRange)
        .toList();
  }

  // This function should return a table of data with the same time range as the graph. Scrollable.
  Widget _buildDataTable() {
    // Fill the rest of the screen but allow scrolling fill horizontally but no scrolling
    return Expanded(
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                columns: const <DataColumn>[
                  DataColumn(label: Text('Time')),
                  DataColumn(label: Text('Voltage')),
                ],
                rows: _data
                    .map((data) => DataRow(
                          cells: <DataCell>[
                            DataCell(Text(data.time.toString())),
                            DataCell(Text(data.voltage.toStringAsFixed(2)))
                          ],
                          color: WidgetStateProperty.resolveWith((states) {
                            if (data.voltage < _blackUpperBound) {
                              return Colors.black.withOpacity(0.2);
                            } else if (data.voltage < _redUpperBound) {
                              return Colors.red.withOpacity(0.2);
                            } else if (data.voltage < _yellowUpperBound) {
                              return Colors.yellow.withOpacity(0.2);
                            } else {
                              return Colors.green.withOpacity(0.2);
                            }
                          }),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Graph and below controls < 10 s > (< = decrease, > = increase)
  Widget _buildGraph() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainer,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
      child: Column(
        children: [
          SfCartesianChart(
            primaryXAxis: const DateTimeAxis(),
            primaryYAxis: const NumericAxis(minimum: 0, maximum: 20),
            series: <CartesianSeries<_Data, DateTime>>[
              RangeAreaSeries<_Data, DateTime>(
                dataSource: _data,
                xValueMapper: (_Data data, _) => data.time,
                lowValueMapper: (_Data data, _) => _yellowLowerBound,
                highValueMapper: (_Data data, _) => _yellowUpperBound,
                color: Colors.yellow.withOpacity(0.2),
              ),
              RangeAreaSeries<_Data, DateTime>(
                dataSource: _data,
                xValueMapper: (_Data data, _) => data.time,
                lowValueMapper: (_Data data, _) => _redLowerBound,
                highValueMapper: (_Data data, _) => _redUpperBound,
                color: Colors.red.withOpacity(0.2),
              ),
              RangeAreaSeries<_Data, DateTime>(
                dataSource: _data,
                xValueMapper: (_Data data, _) => data.time,
                lowValueMapper: (_Data data, _) => _blackLowerBound,
                highValueMapper: (_Data data, _) => _blackUpperBound,
                color: Colors.black.withOpacity(0.2),
              ),
              LineSeries<_Data, DateTime>(
                // draw a line as error region
                dataSource: _data,
                xValueMapper: (_Data data, _) => data.time,
                yValueMapper: (_Data data, _) => data.voltage,
                color: Colors.blue,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // DateTime range control (03.08.2024 12:00:00 - 03.08.2024 12:00:10)

            ],
          ),
        ],
      ),
    );
  }
}
