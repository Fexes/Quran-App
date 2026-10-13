import 'package:flutter/foundation.dart';

/// Invalidates session indexes when locally searchable content changes.
class LocalSearchRevision {
  LocalSearchRevision._();
  static int value = 0;
  static final changes = ValueNotifier<int>(0);
  static void changed() {
    value++;
    changes.value = value;
  }
}
