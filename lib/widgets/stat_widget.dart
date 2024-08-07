import 'dart:async';

import 'package:flutter/material.dart';
import 'package:volt_vole/battery_device.dart';
import 'package:volt_vole/utils.dart';

class StatWidget extends StatefulWidget {
  final String label;
  final String value;
  final DateTime? time;
  final Color? mainColor;

  const StatWidget(
      {super.key,
      this.mainColor,
      required this.label,
      required this.value,
      required this.time});

  @override
  _StatWidgetState createState() => _StatWidgetState();
}

class _StatWidgetState extends State<StatWidget> {
  late Timer _timer;
  Duration? _currentTimerDuration;

  @override
  void initState() {
    super.initState();
    _currentTimerDuration = getDuration() ?? const Duration(seconds: 1);
    _timer = Timer.periodic(_currentTimerDuration!, (timer) {
      _timerTick();
    });
  }

  void _timerTick() {
    if (!mounted || widget.time == null) {
      return;
    }
    // If we're >60 seconds change update rate to 1 minute
    if (DateTime.now().difference(widget.time!).inSeconds > 60) {
      scheduleNewTimer();
    } else if (DateTime.now().difference(widget.time!).inHours > 1) {
      scheduleNewTimer();
    }

    setState(() {});
  }

  Duration? getDuration() {
    if (widget.time == null) {
      return null;
    }

    if (DateTime.now().difference(widget.time!).inSeconds > 60) {
      return const Duration(minutes: 1);
    } else if (DateTime.now().difference(widget.time!).inHours > 1) {
      return const Duration(hours: 1);
    } else if (DateTime.now().difference(widget.time!).inDays > 1) {
      return const Duration(days: 1);
    }

    return const Duration(seconds: 1);
  }

  void scheduleNewTimer() {
    var newDuration = getDuration();
    if (newDuration == null) {
      return;
    }
    if (_currentTimerDuration != null && newDuration == _currentTimerDuration) {
      return;
    }

    if (_timer.isActive) {
      _timer.cancel();
    }

    _currentTimerDuration = newDuration;
    _timer = Timer.periodic(newDuration, (_) => _timerTick());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _getDateTime() {
    if (widget.time == null) {
      return 'N/A';
    }

    var statTime = widget.time!;
    // If the date is not today
    if (!DateTimeUtils.isToday(statTime)) {
      return "${DateTimeUtils.getFormattedDate(statTime)} ${DateTimeUtils.getFormattedTime(statTime)}";
    } else {
      return DateTimeUtils.getTimeAgo(statTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.time == null) {
          return;
        }
        showMoreInfoDialog(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  widget.label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Text(
                widget.value,
                style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                      color: widget.mainColor,
                    ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _getDateTime(),
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showMoreInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.label),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Value: "),
                Text(widget.value, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: widget.mainColor)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("At: "),
                Text(DateTimeUtils.getTimeAgo(widget.time!)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(""),
                Text(DateTimeUtils.getFormattedDateTime(widget.time!)),
              ],
            ),
          ],
        )
      ),
    );
  }
}
