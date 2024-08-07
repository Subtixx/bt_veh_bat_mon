import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:volt_vole/battery_device.dart';
import 'package:volt_vole/settings.dart';
import 'package:volt_vole/utils.dart';
import 'package:volt_vole/voltage_data.dart';

class ChartWidget extends StatelessWidget {
  final double _yellowLowerBound = Settings().yellowLowerBound;
  final double _yellowUpperBound = Settings().yellowUpperBound;
  final double _redLowerBound = Settings().redLowerBound;
  final double _redUpperBound = Settings().redUpperBound;

  final List<VoltageData> _voltages;

  ChartWidget(this._voltages, {super.key});

  VoltageData get _highestVoltage => _voltages.reduce((a, b) => a.voltage > b.voltage ? a : b);
  VoltageData get _lowestVoltage => _voltages.reduce((a, b) => a.voltage < b.voltage ? a : b);

  double _getLowestValue() {
    return (_lowestVoltage.voltage).floor() - 1.0;
  }

  double _getHighestValue() {
    return (_highestVoltage.voltage).ceil() + 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      /*loadMoreIndicatorBuilder:
          (BuildContext context, ChartSwipeDirection direction) =>
              getLoadMoreViewBuilder(context, direction),*/
      enableAxisAnimation: false,
      zoomPanBehavior: ZoomPanBehavior(
        enablePinching: true,
        enablePanning: true,
        maximumZoomLevel: 0.5,
        enableDoubleTapZooming: true,
        enableMouseWheelZooming: true,
        enableSelectionZooming: false,
        selectionRectBorderColor: Colors.red,
        selectionRectBorderWidth: 1,
        selectionRectColor: Colors.grey,
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        format: 'point.y V',
        builder: (dynamic data, dynamic point, dynamic series, int pointIndex,
            int seriesIndex) {
          if (data is VoltageData) {
            return Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateTimeUtils.getFormattedDateTime(data.timestamp),
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                  Text(
                    '${data.voltage.toStringAsFixed(2)} V',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium!
                        .copyWith(color: data.getColor()),
                  ),
                ],
              ),
            );
          } else {
            return const Text('');
          }
        },
      ),
      primaryXAxis: DateTimeAxis(
        dateFormat: Settings().dayFilter >= 24 ? DateFormat('dd/MM') : DateFormat('HH:mm'),
        intervalType: DateTimeIntervalType.hours,
        interval: Settings().dayFilter.toDouble(),
        //majorGridLines: MajorGridLines(width: 1, color: Colors.grey.withOpacity(0.5), dashArray: const <double>[5, 5]),
        /*intervalType: DateTimeIntervalType.seconds,
          interval: 1,*/
      ),
      primaryYAxis: NumericAxis(
        decimalPlaces: 1,
        majorGridLines: MajorGridLines(width: 1, color: Colors.grey.withOpacity(0.5), dashArray: const <double>[5, 5]),
        interval: 0.5,
        minimum: _getLowestValue(),
        maximum: _getHighestValue(),
      ),
      crosshairBehavior: CrosshairBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        lineDashArray: const <double>[5, 5],
        lineColor: Colors.grey.withOpacity(0.5),
      ),
      series: <CartesianSeries<VoltageData, DateTime>>[
        RangeAreaSeries<VoltageData, DateTime>(
          dataSource: _voltages,
          enableTooltip: false,
          xValueMapper: (VoltageData data, _) => data.timestamp,
          lowValueMapper: (VoltageData data, _) => _yellowLowerBound,
          highValueMapper: (VoltageData data, _) => _yellowUpperBound,
          color: Colors.yellow.withOpacity(0.2),
        ),
        RangeAreaSeries<VoltageData, DateTime>(
          dataSource: _voltages,
          enableTooltip: false,
          xValueMapper: (VoltageData data, _) => data.timestamp,
          lowValueMapper: (VoltageData data, _) => _redLowerBound,
          highValueMapper: (VoltageData data, _) => _redUpperBound,
          color: Theme.of(context).colorScheme.error.withOpacity(0.2),
        ),
        LineSeries<VoltageData, DateTime>(
          name: 'Voltages',
          pointColorMapper: (VoltageData voltage, _) => voltage.getColor(),
          dataLabelMapper: (VoltageData voltage, _) => '${voltage.voltage.toStringAsFixed(2)} V',
          dataLabelSettings: const DataLabelSettings(isVisible: true, labelPosition: ChartDataLabelPosition.outside),
          enableTooltip: true,
          color: Theme.of(context).colorScheme.primary,
          dataSource: _voltages,
          xValueMapper: (VoltageData voltage, _) => voltage.timestamp,
          yValueMapper: (VoltageData voltage, _) => voltage.voltage,
          markerSettings: MarkerSettings(isVisible: true, borderWidth: 0, color: Theme.of(context).colorScheme.primary),
        ),
      ],
    );
  }

  Widget getLoadMoreViewBuilder(
      BuildContext context, ChartSwipeDirection direction) {
    if (direction == ChartSwipeDirection.end) {
      return FutureBuilder<String>(
        future: Future.delayed(const Duration(seconds: 3), () => 'done'),
        builder: (BuildContext futureContext, AsyncSnapshot<String> snapShot) {
          return snapShot.connectionState != ConnectionState.done
              ? const CircularProgressIndicator()
              : SizedBox.fromSize(size: Size.zero);
        },
      );
    } else {
      return SizedBox.fromSize(size: Size.zero);
    }
  }
}
