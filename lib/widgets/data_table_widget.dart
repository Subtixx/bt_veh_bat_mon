import 'package:flutter/material.dart';
import 'package:volt_vole/battery_device.dart';
import 'package:volt_vole/utils.dart';
import 'package:volt_vole/voltage_data.dart';

class DataTableWidget extends StatelessWidget {
  final List<VoltageData> _voltages;

  const DataTableWidget(this._voltages, {super.key});

  List<VoltageData> getFilteredData() {
    return _voltages; //.where((element) => element.voltage <= 9.0).toList();
  }

  @override
  Widget build(BuildContext context) {
    var filteredData = getFilteredData();
    return filteredData.isEmpty
        ? Center(child: Text('No Data', style: Theme.of(context).textTheme.headlineLarge))
        : ListView.builder(
            itemCount: filteredData.length,
            itemBuilder: (context, index) {
              var voltage = filteredData[index];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                decoration: BoxDecoration(
                  color: voltage.getColor().withOpacity(0.2),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                            child: Text(DateTimeUtils.getFormattedDate(
                                voltage.timestamp))),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                            child: Text(DateTimeUtils.getFormattedTime(
                                voltage.timestamp))),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                            child:
                                Text('${voltage.voltage.toStringAsFixed(2)}V')),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }
}
