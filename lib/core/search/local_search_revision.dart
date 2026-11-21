import 'package:flutter/foundation.dart';

/// Invalidates local indexes after a successful content mutation.
class LocalSearchRevision {
  LocalSearchRevision._();
  static int value = 0;
  static final changes = ValueNotifier<int>(0);
  static final String session = DateTime.now().microsecondsSinceEpoch
      .toString();
  static final _sources = <String, int>{};
  static String forSource(String source) =>
      '$session:${_sources['all'] ?? 0}:${_sources[source] ?? 0}';

  static void changed({String source = 'all'}) {
    _sources.update(source, (value) => value + 1, ifAbsent: () => 1);
    value++;
    changes.value = value;
  }
}
