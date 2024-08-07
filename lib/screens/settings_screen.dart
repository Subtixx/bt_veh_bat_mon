import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:volt_vole/database.dart';
import 'package:volt_vole/logging.dart';
import 'package:volt_vole/settings.dart';
import 'package:volt_vole/version.dart';
import 'package:volt_vole/voltage_data.dart';
import 'package:volt_vole/widgets/double_input_widget.dart';
import 'package:volt_vole/widgets/int_input_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  List<DropdownMenuItem<int>> getIntervalList() {
    var intervalList = <DropdownMenuItem<int>>[];
    for(var interval in Settings.INTERVALS){
      var text = '$interval hours';
      if (interval > 24) {
        text = '${(interval / 24).toStringAsFixed(0)} days';
      }
      intervalList.add(DropdownMenuItem(
        value: interval,
        child: Text(text),
      ));
    }
    return intervalList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filter'),
              DropdownButton(
                items: getIntervalList(),
                onChanged: (value) {
                  Settings().dayFilter = value ?? Settings.INTERVALS.first;
                  setState(() {});
                },
                value: Settings().dayFilter,
              ),
            ],
          ),
          buildSettingsRow(
              'Show All Devices',
              Switch(
                value: Settings().showAllDevices,
                onChanged: (bool value) {
                  Settings().showAllDevices = value;
                  setState(() {});
                },
              )),
          buildSettingsRow(
              'Show Unknown Devices',
              Switch(
                value: Settings().showUnknownDevices,
                onChanged: (bool value) {
                  Settings().showUnknownDevices = value;
                  setState(() {});
                },
              )),
          buildSettingsRow(
              'Stop After Device Found',
              Switch(
                value: Settings().stopAfterDeviceFound,
                onChanged: (bool value) {
                  Settings().stopAfterDeviceFound = value;
                  setState(() {});
                },
              )),
          buildSettingsRow(
              'Show Duplicated Entries',
              Switch(
                value: Settings().showDuplicatedEntries,
                onChanged: (bool value) {
                  Settings().showDuplicatedEntries = value;
                  setState(() {});
                },
              )),
          const Divider(),
          buildSettingsRow(
            'Red lower bound',
            Expanded(
              child: DoubleInputWidget(
                  initialValue: Settings().redLowerBound,
                  onCommit: (double value) {
                    Settings().redLowerBound = value;
                    setState(() {});
                  }),
            ),
          ),
          buildSettingsRow(
            'Red upper bound',
            Expanded(
              child: DoubleInputWidget(
                  initialValue: Settings().redUpperBound,
                  onCommit: (double value) {
                    Settings().redUpperBound = value;
                    setState(() {});
                  }),
            ),
          ),
          buildSettingsRow(
            'Yellow lower bound',
            Expanded(
              child: DoubleInputWidget(
                  initialValue: Settings().yellowLowerBound,
                  onCommit: (double value) {
                    Settings().yellowLowerBound = value;
                    setState(() {});
                  }),
            ),
          ),
          buildSettingsRow(
            'Yellow upper bound',
            Expanded(
              child: DoubleInputWidget(
                  initialValue: Settings().yellowUpperBound,
                  onCommit: (double value) {
                    Settings().yellowUpperBound = value;
                    setState(() {});
                  }),
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                child: const Text('Reset Database'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Database has been reset'),
                    ),
                  );
                  Database.instance.deleteAll();
                  setState(() {});
                },
              ),
              TextButton(
                child: const Text('Randomize Database'),
                onPressed: () {
                  Database.instance.insertAll(VoltageData.randomData());
                },
              ),
            ],
          ),

          buildSettingsFooter(),
        ],
      ),
    );
  }

  Widget buildSettingsFooter() {
    return Column(
      children: [
        Text('Version ${version.toString()}'),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Made with ❤️ and ☕ by'),
            GestureDetector(
              onTap: () {
                // Open link in browser
                launchUrl(
                  Uri.parse('https://github.com/subtixx'),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: Text(' Dominic Hock', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            )
          ],
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12.0),
          child: GestureDetector(
            onTap: () {
              // Open link in browser
              launchUrl(
                Uri.parse('https://github.com/Subtixx/bt_veh_bat_mon'),
                mode: LaunchMode.externalApplication,
              );
            },
            child: Text('View on GitHub', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          ),
        ),
      ],
    );
  }

  Widget buildSettingsRow(String title, Widget widget) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        widget,
      ],
    );
  }
}
