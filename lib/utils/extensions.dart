import 'dart:async';
import 'package:flutter/foundation.dart';

extension ValueNotifierExtension<T> on ValueNotifier<T> {
  Stream<T> get asBroadcastStream {
    final controller = StreamController<T>.broadcast();

    controller.add(value);

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
