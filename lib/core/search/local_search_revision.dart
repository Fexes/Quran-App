import 'dart:convert';

import 'package:crypto/crypto.dart';
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

  /// Deterministic persisted-content identity. Streaming scalars avoids a
  /// second full JSON/UTF-8 copy of large downloaded language stores.
  static String fingerprint(Object? snapshot) {
    final output = _DigestSink();
    final input = sha256.startChunkedConversion(output);
    void add(Object? value) {
      if (value is Map) {
        input.add(const [123]);
        final entries = value.entries.toList()
          ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
        for (final entry in entries) {
          input.add(utf8.encode(jsonEncode(entry.key.toString())));
          input.add(const [58]);
          add(entry.value);
          input.add(const [44]);
        }
        input.add(const [125]);
      } else if (value is Iterable) {
        input.add(const [91]);
        for (final item in value) {
          add(item);
          input.add(const [44]);
        }
        input.add(const [93]);
      } else {
        input.add(utf8.encode(jsonEncode(value)));
      }
    }

    add(snapshot);
    input.close();
    return output.value!.toString();
  }
}

class _DigestSink implements Sink<Digest> {
  Digest? value;
  @override
  void add(Digest data) => value = data;
  @override
  void close() {}
}
