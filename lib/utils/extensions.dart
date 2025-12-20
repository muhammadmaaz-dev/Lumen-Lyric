import 'dart:async';
import 'package:flutter/foundation.dart';

// Ye extension ValueNotifier ko Stream mein convert karti hai
extension ValueListenableStream<T> on ValueListenable<T> {
  Stream<T> get asBroadcastStream {
    final controller = StreamController<T>.broadcast();

    // 1. Jaise hi koi listen kare, usay current value bhej do
    controller.add(this.value);

    // 2. Jab bhi value change ho, stream mein naya data daal do
    void listener() {
      controller.add(this.value);
    }

    this.addListener(listener);

    // 3. Jab koi sunna band kar de, to listener hata do (Memory Leak se bachne ke liye)
    controller.onCancel = () {
      this.removeListener(listener);
    };

    return controller.stream;
  }
}
