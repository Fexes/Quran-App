import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:characters/characters.dart';

import 'offline_search_normalizer.dart';

/// The unpadded int64 tensors expected by multilingual E5's ONNX export.
final class E5Encoding {
  E5Encoding._(List<int> ids)
    : inputIds = Int64List.fromList(ids),
      attentionMask = Int64List.fromList(List.filled(ids.length, 1)),
      tokenTypeIds = Int64List(ids.length);

  final Int64List inputIds;
  final Int64List attentionMask;
  final Int64List tokenTypeIds;

  int get length => inputIds.length;
}

/// Loads the complete Hugging Face Unigram normalization/tokenization pipeline.
final class E5Tokenizer {
  E5Tokenizer._(
    this._vocabulary,
    this._unknownId,
    this._scores,
    this._specialIds,
    this._specialPattern,
    this._startId,
    this._endId,
    this._marker,
    this._unknownScore,
    this._normalizer,
  );

  static const int maxLength = 512;
  final _CompactVocabulary _vocabulary;
  final int _unknownId;
  final Float64List _scores;
  final Map<String, int> _specialIds;
  final RegExp _specialPattern;
  final int _startId;
  final int _endId;
  final String _marker;
  final double _unknownScore;
  final _HfPrecompiledNormalizer _normalizer;

  static E5Tokenizer fromFile(String path) {
    final data =
        jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    _validatePostProcessor(data);
    final model = data['model'] as Map;
    final vocab = model['vocab'] as List;
    final scores = Float64List(vocab.length);
    var minimumScore = double.infinity;
    for (var i = 0; i < vocab.length; i++) {
      final score = ((vocab[i] as List)[1] as num).toDouble();
      scores[i] = score;
      if (score < minimumScore) minimumScore = score;
    }
    final specialIds = <String, int>{};
    for (final token in data['added_tokens'] as List) {
      final added = token as Map;
      if (added['normalized'] != false ||
          added['single_word'] != false ||
          added['lstrip'] != false ||
          added['rstrip'] != false) {
        throw const FormatException('Unsupported E5 added-token flags');
      }
      specialIds[added['content'] as String] = added['id'] as int;
    }
    final names = specialIds.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final processor = data['post_processor'] as Map;
    final template = processor['single'] as List;
    final declared = processor['special_tokens'] as Map;
    int specialId(int index) =>
        (declared[(template[index] as Map)['SpecialToken']['id']]['ids']
                    as List)
                .single
            as int;
    final preTokenizer = data['pre_tokenizer'] as Map;
    if (preTokenizer['type'] != 'Metaspace' ||
        preTokenizer['add_prefix_space'] != true ||
        preTokenizer['split'] == false) {
      throw const FormatException('Unsupported E5 metaspace configuration');
    }
    final normalizers = (data['normalizer'] as Map)['normalizers'] as List;
    if (normalizers.length != 2 ||
        normalizers[0]['type'] != 'Precompiled' ||
        normalizers[1]['type'] != 'Replace' ||
        normalizers[1]['pattern']['Regex'] != ' {2,}' ||
        normalizers[1]['content'] != ' ') {
      throw const FormatException('Unsupported E5 normalization pipeline');
    }
    return E5Tokenizer._(
      _CompactVocabulary(vocab),
      model['unk_id'] as int,
      scores,
      specialIds,
      RegExp(names.map(RegExp.escape).join('|')),
      specialId(0),
      specialId(2),
      preTokenizer['replacement'] as String,
      minimumScore - 10,
      _HfPrecompiledNormalizer(
        base64Decode(normalizers[0]['precompiled_charsmap'] as String),
      ),
    );
  }

  E5Encoding encodeQuery(String text) => _encode('query: ', text);

  E5Encoding encodePassage(String text) => _encode('passage: ', text);

  E5Encoding _encode(String prefix, String text) {
    final content = _tokens('$prefix${OfflineSearchNormalizer.semantic(text)}');
    return E5Encoding._([_startId, ...content.take(maxLength - 2), _endId]);
  }

  /// Same passage-prefix windows and 64-token overlap as the build-time encoder.
  Iterable<E5Encoding> encodePassageChunks(String text) sync* {
    // Local notes/generated documents have no fixed length. Bound normalization
    // and Viterbi work before tokenization, preserving overlap and all text.
    const window = 8192;
    var start = 0;
    do {
      var end = (start + window).clamp(0, text.length);
      if (end < text.length) {
        final space = text.lastIndexOf(' ', end);
        if (space > start + window ~/ 2) end = space;
        if (end > 0 &&
            text.codeUnitAt(end - 1) >= 0xd800 &&
            text.codeUnitAt(end - 1) <= 0xdbff) {
          end--;
        }
      }
      yield* _encodePassageWindow(text.substring(start, end));
      if (end == text.length) break;
      start = end - 256;
      if (text.codeUnitAt(start) >= 0xdc00 &&
          text.codeUnitAt(start) <= 0xdfff) {
        start++;
      }
    } while (start < text.length);
  }

  Iterable<E5Encoding> _encodePassageWindow(String text) sync* {
    final prefix = _tokens('passage:');
    final raw = _tokens('passage: ${OfflineSearchNormalizer.semantic(text)}');
    final body = raw.sublist(prefix.length);
    final capacity = maxLength - prefix.length - 2;
    var start = 0;
    while (true) {
      final end = (start + capacity).clamp(0, body.length);
      yield E5Encoding._([
        _startId,
        ...prefix,
        ...body.sublist(start, end),
        _endId,
      ]);
      if (end == body.length) break;
      start += capacity - 64;
    }
  }

  List<int> _tokens(String input) {
    final content = <int>[];
    var cursor = 0;
    for (final match in _specialPattern.allMatches(input)) {
      _encodeSegment(input.substring(cursor, match.start), content);
      content.add(_specialIds[match.group(0)]!);
      cursor = match.end;
    }
    _encodeSegment(input.substring(cursor), content);
    return content;
  }

  void _encodeSegment(String input, List<int> output) {
    if (input.isEmpty) return;
    var normalized = _normalizer
        .normalize(input)
        .replaceAll(RegExp(' {2,}'), ' ')
        .replaceAll(' ', _marker);
    if (normalized.isEmpty) return;
    if (!normalized.startsWith(_marker)) normalized = '$_marker$normalized';
    // HF Metaspace retains whitespace-only chunks. Run the exact model on
    // every retained chunk, including a marker with no following letters.
    var start = 0;
    while (start < normalized.length) {
      final next = normalized.indexOf(_marker, start + _marker.length);
      final end = next < 0 ? normalized.length : next;
      output.addAll(_unigram(normalized.substring(start, end)));
      start = end;
    }
  }

  List<int> _unigram(String input) {
    final best = Float64List(input.length + 1)
      ..fillRange(0, input.length + 1, double.negativeInfinity);
    final previous = Int32List(input.length + 1)
      ..fillRange(0, input.length + 1, -1);
    final tokenIds = Int32List(input.length + 1);
    best[0] = 0;
    var start = 0;
    while (start < input.length) {
      final unit = input.codeUnitAt(start);
      final charEnd =
          start +
          (unit >= 0xd800 && unit <= 0xdbff && start + 1 < input.length
              ? 2
              : 1);
      var hasSingle = false;
      for (final (id, end) in _vocabulary.findAllPrefixes(input, start)) {
        final candidate = best[start] + _scores[id];
        if (previous[end] < 0 || candidate > best[end]) {
          best[end] = candidate;
          previous[end] = start;
          tokenIds[end] = id;
        }
        if (end == charEnd) hasSingle = true;
      }
      // HF uses minimum vocabulary score minus 10, with a fallback whenever
      // no one-codepoint piece exists, even when a longer prefix does exist.
      if (!hasSingle) {
        final candidate = best[start] + _unknownScore;
        if (previous[charEnd] < 0 || candidate > best[charEnd]) {
          best[charEnd] = candidate;
          previous[charEnd] = start;
          tokenIds[charEnd] = _unknownId;
        }
      }
      start = charEnd;
    }
    final reversed = <int>[];
    var end = input.length;
    while (end > 0) {
      final id = tokenIds[end];
      if (id != _unknownId || reversed.isEmpty || reversed.last != id) {
        reversed.add(id);
      }
      end = previous[end];
    }
    return reversed.reversed.toList();
  }

  static void _validatePostProcessor(Map<String, dynamic> data) {
    final processor = data['post_processor'];
    if (data['model'] is! Map ||
        (data['model'] as Map)['type'] != 'Unigram' ||
        processor is! Map ||
        processor['type'] != 'TemplateProcessing') {
      throw const FormatException('Unsupported multilingual E5 tokenizer');
    }
    final template = processor['single'];
    if (template is! List ||
        template.length != 3 ||
        template[0] is! Map ||
        template[1] is! Map ||
        template[2] is! Map ||
        !(template[0] as Map).containsKey('SpecialToken') ||
        !(template[1] as Map).containsKey('Sequence') ||
        !(template[2] as Map).containsKey('SpecialToken')) {
      throw const FormatException('Unsupported multilingual E5 token template');
    }
  }
}

/// Sorted UTF-16 pieces use contiguous storage rather than allocating a map
/// and trie node for every prefix in E5's 250,002-piece vocabulary.
final class _CompactVocabulary {
  _CompactVocabulary(List<dynamic> entries) {
    _ids = Uint32List(entries.length);
    var characterCount = 0;
    for (var id = 0; id < entries.length; id++) {
      _ids[id] = id;
      characterCount += ((entries[id] as List)[0] as String).length;
    }
    _ids.sort((a, b) {
      final comparison = ((entries[a] as List)[0] as String).compareTo(
        (entries[b] as List)[0] as String,
      );
      return comparison != 0 ? comparison : a.compareTo(b);
    });
    _characters = Uint16List(characterCount);
    _offsets = Uint32List(entries.length + 1);
    var cursor = 0;
    for (var index = 0; index < _ids.length; index++) {
      _offsets[index] = cursor;
      final piece = (entries[_ids[index]] as List)[0] as String;
      for (var unit = 0; unit < piece.length; unit++) {
        _characters[cursor++] = piece.codeUnitAt(unit);
      }
    }
    _offsets.last = cursor;
  }

  late final Uint32List _ids;
  late final Uint32List _offsets;
  late final Uint16List _characters;

  Iterable<(int id, int end)> findAllPrefixes(String input, int start) sync* {
    var lower = 0;
    var upper = _ids.length;
    for (var depth = 0; start + depth < input.length; depth++) {
      final codeUnit = input.codeUnitAt(start + depth);
      final first = _lowerBound(lower, upper, depth, codeUnit);
      upper = _lowerBound(first, upper, depth, codeUnit + 1);
      lower = first;
      if (lower >= upper) return;
      final length = depth + 1;
      if (_offsets[lower + 1] - _offsets[lower] == length) {
        // HF's vocabulary map keeps the final ID for duplicate token strings.
        final afterTerminal = _lowerBound(lower, upper, length, 0);
        yield (_ids[afterTerminal - 1], start + length);
      }
    }
  }

  int _lowerBound(int lower, int upper, int depth, int codeUnit) {
    while (lower < upper) {
      final middle = lower + ((upper - lower) >> 1);
      final offset = _offsets[middle] + depth;
      final value = offset < _offsets[middle + 1] ? _characters[offset] : -1;
      if (value < codeUnit) {
        lower = middle + 1;
      } else {
        upper = middle;
      }
    }
    return lower;
  }
}

/// Match HF tokenizers 0.22's Precompiled behavior, including its grapheme
/// fast path. SentencePiece's longest-prefix normalizer differs on stacked
/// combining marks, so using it would change the offline query vectors.
final class _HfPrecompiledNormalizer {
  _HfPrecompiledNormalizer(Uint8List bytes) {
    if (bytes.length < 4) {
      throw const FormatException('Invalid E5 precompiled normalizer');
    }
    final data = ByteData.sublistView(bytes);
    final trieBytes = data.getUint32(0, Endian.little);
    if (trieBytes == 0 || trieBytes % 4 != 0 || trieBytes + 4 > bytes.length) {
      throw const FormatException('Invalid E5 normalizer trie');
    }
    _table = Uint32List(trieBytes ~/ 4);
    for (var i = 0; i < _table.length; i++) {
      _table[i] = data.getUint32(4 + 4 * i, Endian.little);
    }
    _strings = bytes.sublist(4 + trieBytes);
  }

  late final Uint32List _table;
  late final Uint8List _strings;
  final _cache = <int, String>{};

  String normalize(String input) {
    final output = StringBuffer();
    for (final grapheme in input.characters) {
      if (utf8.encode(grapheme).length < 6) {
        final mapped = _transform(grapheme);
        if (mapped != null) {
          output.write(mapped);
          continue;
        }
      }
      for (final rune in grapheme.runes) {
        final character = String.fromCharCode(rune);
        output.write(_transform(character) ?? character);
      }
    }
    return output.toString();
  }

  String? _transform(String input) {
    var position = _offset(_table.first);
    for (final byte in utf8.encode(input)) {
      position ^= byte;
      if (position >= _table.length) return null;
      final unit = _table[position];
      if ((unit & 0x800000ff) != byte) return null;
      position ^= _offset(unit);
      if (((unit >> 8) & 1) != 0) {
        if (position >= _table.length) {
          throw const FormatException('Invalid E5 normalizer leaf');
        }
        final stringOffset = _table[position] & 0x7fffffff;
        return _cache.putIfAbsent(stringOffset, () {
          if (stringOffset >= _strings.length) {
            throw const FormatException('Invalid E5 normalizer string');
          }
          var end = stringOffset;
          while (end < _strings.length && _strings[end] != 0) {
            end++;
          }
          return utf8.decode(_strings.sublist(stringOffset, end));
        });
      }
    }
    return null;
  }

  static int _offset(int unit) => (unit >> 10) << ((unit & (1 << 9)) >> 6);
}
