import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';

// It is essentially a stream but:
//  1. we cache the latestValue of the stream
//  2. the "latestValue" is re-emitted whenever the stream is listened to
class StreamControllerReemit<T> {
  T? _latestValue;

  final StreamController<T> _controller = StreamController<T>.broadcast();

  StreamControllerReemit({T? initialValue}) : _latestValue = initialValue;

  Stream<T> get stream {
    return _latestValue != null
        ? _controller.stream.newStreamWithInitialValue(_latestValue!)
        : _controller.stream;
  }

  T? get value => _latestValue;

  void add(T newValue) {
    _latestValue = newValue;
    _controller.add(newValue);
  }

  Future<void> close() {
    return _controller.close();
  }
}

// return a new stream that immediately emits an initial value
extension _StreamNewStreamWithInitialValue<T> on Stream<T> {
  Stream<T> newStreamWithInitialValue(T initialValue) {
    return transform(_NewStreamWithInitialValueTransformer(initialValue));
  }
}

// Helper for 'newStreamWithInitialValue' method for streams.
class _NewStreamWithInitialValueTransformer<T>
    extends StreamTransformerBase<T, T> {
  /// the initial value to push to the new stream
  final T initialValue;

  /// controller for the new stream
  late StreamController<T> controller;

  /// subscription to the original stream
  late StreamSubscription<T> subscription;

  /// new stream listener count
  var listenerCount = 0;

  _NewStreamWithInitialValueTransformer(this.initialValue);

  @override
  Stream<T> bind(Stream<T> stream) {
    if (stream.isBroadcast) {
      return _bind(stream, broadcast: true);
    } else {
      return _bind(stream);
    }
  }

  Stream<T> _bind(Stream<T> stream, {bool broadcast = false}) {
    /////////////////////////////////////////
    /// Original Stream Subscription Callbacks
    ///

    /// When the original stream emits data, forward it to our new stream
    void onData(T data) {
      controller.add(data);
    }

    /// When the original stream is done, close our new stream
    void onDone() {
      controller.close();
    }

    /// When the original stream has an error, forward it to our new stream
    void onError(Object error) {
      controller.addError(error);
    }

    /// When a client listens to our new stream, emit the
    /// initial value and subscribe to original stream if needed
    void onListen() {
      // Emit the initial value to our new stream
      controller.add(initialValue);

      // listen to the original stream, if needed
      if (listenerCount == 0) {
        subscription = stream.listen(
          onData,
          onError: onError,
          onDone: onDone,
        );
      }

      // count listeners of the new stream
      listenerCount++;
    }

    //////////////////////////////////////
    ///  New Stream Controller Callbacks
    ///

    /// (Single Subscription Only) When a client pauses
    /// the new stream, pause the original stream
    void onPause() {
      subscription.pause();
    }

    /// (Single Subscription Only) When a client resumes
    /// the new stream, resume the original stream
    void onResume() {
      subscription.resume();
    }

    /// Called when a client cancels their
    /// subscription to the new stream,
    void onCancel() {
      // count listeners of the new stream
      listenerCount--;

      // when there are no more listeners of the new stream,
      // cancel the subscription to the original stream,
      // and close the new stream controller
      if (listenerCount == 0) {
        subscription.cancel();
        controller.close();
      }
    }

    //////////////////////////////////////
    /// Return New Stream
    ///

    // create a new stream controller
    if (broadcast) {
      controller = StreamController<T>.broadcast(
        onListen: onListen,
        onCancel: onCancel,
      );
    } else {
      controller = StreamController<T>(
        onListen: onListen,
        onPause: onPause,
        onResume: onResume,
        onCancel: onCancel,
      );
    }

    return controller.stream;
  }
}

final Map<DeviceIdentifier, StreamControllerReemit<bool>> _cglobal = {};
final Map<DeviceIdentifier, StreamControllerReemit<bool>> _dglobal = {};

/// connect & disconnect + update stream
extension Extra on BluetoothDevice {
  // convenience
  StreamControllerReemit<bool> get _cstream {
    _cglobal[remoteId] ??= StreamControllerReemit(initialValue: false);
    return _cglobal[remoteId]!;
  }

  // convenience
  StreamControllerReemit<bool> get _dstream {
    _dglobal[remoteId] ??= StreamControllerReemit(initialValue: false);
    return _dglobal[remoteId]!;
  }

  // get stream
  Stream<bool> get isConnecting {
    return _cstream.stream;
  }

  // get stream
  Stream<bool> get isDisconnecting {
    return _dstream.stream;
  }

  // connect & update stream
  Future<void> connectAndUpdateStream() async {
    _cstream.add(true);
    try {
      await connect(mtu: null);
    } finally {
      _cstream.add(false);
    }
  }

  // disconnect & update stream
  Future<void> disconnectAndUpdateStream({bool queue = true}) async {
    _dstream.add(true);
    try {
      await disconnect(queue: queue);
    } finally {
      _dstream.add(false);
    }
  }
}

class MacAddressUtils {
  static String getCollapsedMacAddress(String mac) {
    // replace 00 with 0 and 01 with 1, 02 with 2, etc.
    RegExp exp = RegExp(r'0([1-9a-f])');
    return mac
        .replaceAll('00', '')
        .replaceAllMapped(exp, (match) => match.group(0)!);
  }
}

class DateTimeUtils {
  static String getFormattedDateTime(DateTime date, {bool addTime = false}) {
    return '${getFormattedDate(date)} ${getFormattedTime(date)}';
  }
  static String getFormattedDate(DateTime date) {
    return DateFormat.yMd().format(date);
  }

  static String getFormattedTime(DateTime date, {bool millisecond = false, bool microsecond = false}) {
    var result = DateFormat.Hms().format(date);
    if (millisecond) {
      result += '.${date.millisecond.toString().padLeft(3, '0')}';
    }
    if (microsecond) {
      result += '.${date.microsecond.toString().padLeft(3, '0')}';
    }
    return result;
  }

  static String getTimeAgo(DateTime date, {bool addTime = false}) {
    var now = DateTime.now();
    var diff = now.difference(date);

    var result = '';
    if (diff.inDays > 365) {
      result = '${(diff.inDays / 365).floor()} ${singleOrPlural((diff.inDays / 365).floor(), 'year', 'years')} ago';
    } else if (diff.inDays > 30) {
      result = '${(diff.inDays / 30).floor()} ${singleOrPlural((diff.inDays / 30).floor(), 'month', 'months')} ago';
    } else if (diff.inDays > 7) {
      result = '${(diff.inDays / 7).floor()} ${singleOrPlural((diff.inDays / 7).floor(), 'week', 'weeks')} ago';
    } else if (diff.inDays > 1) {
      result = '${diff.inDays} ${singleOrPlural(diff.inDays, 'day', 'days')} ago';
    } else if (diff.inDays == 1) {
      result = 'yesterday';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} ${singleOrPlural(diff.inHours, 'hour', 'hours')} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} ${singleOrPlural(diff.inMinutes, 'minute', 'minutes')} ago';
    } else if (diff.inSeconds > 0) {
      return '${diff.inSeconds} ${singleOrPlural(diff.inSeconds, 'second', 'seconds')} ago';
    } else {
      return 'just now';
    }

    if (addTime) {
      result += ' at ${date.hour}:${date.minute}';
    }
    return result;
  }

  static String singleOrPlural(int count, String singular, String plural) {
    if (count == 1) {
      return singular;
    } else {
      return plural;
    }
  }

  static bool isToday(DateTime date) {
    return DateTime.now().difference(date).inDays == 0;
  }
}
