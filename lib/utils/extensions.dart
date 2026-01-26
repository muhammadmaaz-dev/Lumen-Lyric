import 'dart:async';
import 'package:flutter/foundation.dart';

extension ValueNotifierExtension<T> on ValueNotifier<T> {
  /// Converts a ValueNotifier to a broadcast Stream
  Stream<T> get asBroadcastStream {
    final controller = StreamController<T>.broadcast();

    // Emit initial value
    controller.add(value);

    // Listen to changes
    void listener() {
      if (!controller.isClosed) {
        controller.add(value);
      }
    }

    addListener(listener);

    controller.onCancel = () {
      removeListener(listener);
    };

    return controller.stream;
  }
}
