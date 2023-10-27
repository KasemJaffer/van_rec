import 'package:flutter/foundation.dart';
import 'dart:async';

/// A utility class for throttling the execution of a callback function.
class Throttler {
  final int milliseconds;
  Timer? _timer;

  /// Creates a [Throttler] with the specified time interval in milliseconds.
  Throttler({required this.milliseconds});

  /// Runs the provided [action] callback function, throttling its execution.
  ///
  /// If this method is called multiple times within the specified time interval
  /// ([milliseconds]), only the last invocation will result in the [action]
  /// callback being executed. Subsequent calls made within the time interval
  /// will cancel the previously scheduled execution and replace it with the
  /// most recent call.
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  /// Cancels any scheduled execution of the throttled callback.
  void cancel() {
    _timer?.cancel();
  }
}

