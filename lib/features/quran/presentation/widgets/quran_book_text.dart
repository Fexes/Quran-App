import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pretext/flutter_pretext.dart' as pretext;

import '../../../../core/constants/quran_arabic_script.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../domain/entities/quran_ayah.dart';
import '../../domain/entities/quran_surah.dart';
import '../../domain/entities/quran_translation.dart';
import '../../domain/entities/quran_word.dart';
import 'quran_translation_text.dart';

bool hasNextSurah(QuranSurah? surah) {
  return surah != null && surah.number < 114;
}

class QuranBookScrollController {
  final _anchors = <Map<String, GlobalKey>>{};

  BuildContext? contextForVerse(String verseKey) {
    for (final keys in _anchors) {
      final context = keys[verseKey]?.currentContext;
      if (context != null && context.findRenderObject()?.attached == true) {
        return context;
      }
    }
    return null;
  }
}

class CombinedPageText extends StatefulWidget {
  const CombinedPageText({
    super.key,
    required this.ayahs,
    required this.pageWords,
    required this.selectedVerseKey,
    required this.activeAudioVerseKey,
    required this.activeWordVerseKey,
    required this.activeWordIndex,
    required this.currentVerseKey,
    required this.arabicFontScale,
    this.translationFontScale = 1,
    required this.showTranslation,
    this.translationsByVerse = const {},
    this.selectedTranslation,
    this.selectionEnabled = true,
    this.arabicScript = QuranArabicScript.uthmani,
    this.verseKeys,
    this.scrollController,
    required this.onAyahTap,
  });

  final List<QuranAyah> ayahs;
  final List<QuranWord> pageWords;
  final String? selectedVerseKey;
  final String? activeAudioVerseKey;
  final String? activeWordVerseKey;
  final int? activeWordIndex;
  final String? currentVerseKey;
  final double arabicFontScale;
  final double translationFontScale;
  final bool showTranslation;
  final Map<String, String> translationsByVerse;
  final QuranTranslationResource? selectedTranslation;
  final bool selectionEnabled;
  final QuranArabicScript arabicScript;
  final Map<String, GlobalKey>? verseKeys;
  final QuranBookScrollController? scrollController;
  final ValueChanged<QuranAyah> onAyahTap;

  @override
  State<CombinedPageText> createState() => _CombinedPageTextState();
}

class _CombinedPageTextState extends State<CombinedPageText> {
  final _recognizers = <String, TapGestureRecognizer>{};
  // Positioned lists can mount a second copy while jumping. Each copy owns its keys.
  final _localVerseKeys = <String, GlobalKey>{};

  Map<String, GlobalKey>? get _verseKeys =>
      widget.scrollController == null ? widget.verseKeys : _localVerseKeys;

  @override
  void initState() {
    super.initState();
    _syncVerseKeys();
    widget.scrollController?._anchors.add(_localVerseKeys);
  }

  void _syncVerseKeys() {
    final verses = widget.ayahs.map((ayah) => ayah.verseKey).toSet();
    _localVerseKeys.removeWhere((verse, _) => !verses.contains(verse));
    if (widget.scrollController != null) {
      for (final verse in verses) {
        _localVerseKeys.putIfAbsent(
          verse,
          () => GlobalKey(debugLabel: 'book-verse-$verse'),
        );
      }
    }
  }

  @override
  void didUpdateWidget(CombinedPageText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?._anchors.remove(_localVerseKeys);
      widget.scrollController?._anchors.add(_localVerseKeys);
    }
    _syncVerseKeys();
    if (!widget.selectionEnabled) {
      for (final recognizer in _recognizers.values) {
        recognizer.dispose();
      }
      _recognizers.clear();
      return;
    }
    final activeKeys = widget.ayahs.map((ayah) => ayah.verseKey).toSet();
    for (final entry in _recognizers.entries.toList()) {
      if (!activeKeys.contains(entry.key)) {
        entry.value.dispose();
        _recognizers.remove(entry.key);
      }
    }
  }

  @override
  void dispose() {
    widget.scrollController?._anchors.remove(_localVerseKeys);
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontSize: 26 * widget.arabicFontScale,
      fontFamily: widget.arabicScript.fontFamily,
      height: widget.arabicScript.readerLineHeight,
      color: QuranTheme.quranTextNormal(context),
      fontWeight: FontWeight.w700,
    );
    if (widget.showTranslation) {
      if (widget.pageWords.isNotEmpty) {
        return InterlinearBookPageText(
          key: ValueKey(widget.arabicScript),
          arabicScript: widget.arabicScript,
          words: widget.pageWords,
          selectedVerseKey: widget.selectedVerseKey,
          activeAudioVerseKey: widget.activeAudioVerseKey,
          activeWordVerseKey: widget.activeWordVerseKey,
          activeWordIndex: widget.activeWordIndex,
          currentVerseKey: widget.currentVerseKey,
          arabicFontScale: widget.arabicFontScale,
          translationFontScale: widget.translationFontScale,
          translationResource: widget.selectedTranslation,
          onAyahTap: (surahNumber, ayahNumber) => widget.onAyahTap(
            QuranAyah(
              surahNumber: surahNumber,
              number: ayahNumber,
              text: '',
              translation: '',
              page: widget.pageWords.first.page,
              juz: widget.ayahs.isEmpty ? 1 : widget.ayahs.first.juz,
              isSajda: false,
            ),
          ),
          selectionEnabled: widget.selectionEnabled,
          verseKeys: _verseKeys,
        );
      }
      return _FallbackBookPageText(
        key: ValueKey(widget.arabicScript),
        arabicScript: widget.arabicScript,
        ayahs: widget.ayahs,
        selectedVerseKey: widget.selectedVerseKey,
        activeAudioVerseKey: widget.activeAudioVerseKey,
        activeWordVerseKey: widget.activeWordVerseKey,
        activeWordIndex: widget.activeWordIndex,
        currentVerseKey: widget.currentVerseKey,
        arabicFontScale: widget.arabicFontScale,
        translationFontScale: widget.translationFontScale,
        translationsByVerse: widget.translationsByVerse,
        translationResource: widget.selectedTranslation,
        onAyahTap: widget.onAyahTap,
        selectionEnabled: widget.selectionEnabled,
        verseKeys: _verseKeys,
      );
    }

    return _buildArabicOnly(context, baseStyle);
  }

  Widget _buildArabicOnly(BuildContext context, TextStyle? baseStyle) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: RichText(
        textAlign: TextAlign.justify,
        text: TextSpan(
          style: baseStyle,
          children: [
            for (final ayah in widget.ayahs) ...[
              _anchorSpan(ayah.verseKey),
              ..._ayahTextSpans(context, ayah, baseStyle),
              TextSpan(
                text: '﴿${ayah.number}﴾ ',
                recognizer: _recognizerFor(ayah),
                style: baseStyle?.copyWith(
                  color:
                      ayah.verseKey == widget.activeAudioVerseKey ||
                          ayah.verseKey == widget.selectedVerseKey
                      ? QuranTheme.quranTextSelected(context)
                      : QuranTheme.quranTextNormal(context),
                  fontSize: 18 * widget.arabicFontScale,
                  fontWeight: baseStyle.fontWeight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  TapGestureRecognizer? _recognizerFor(QuranAyah ayah) {
    if (!widget.selectionEnabled) {
      return null;
    }
    final recognizer = _recognizers.putIfAbsent(
      ayah.verseKey,
      TapGestureRecognizer.new,
    );
    recognizer.onTap = () => widget.onAyahTap(ayah);
    return recognizer;
  }

  TextStyle? _ayahStyle(BuildContext context, QuranAyah ayah, TextStyle? base) {
    if (ayah.verseKey == widget.activeAudioVerseKey) {
      return base?.copyWith(
        color: QuranTheme.quranTextSelected(context),
        backgroundColor: _ayahHighlightFill(context, audioActive: true),
      );
    }
    if (ayah.verseKey == widget.selectedVerseKey) {
      return base?.copyWith(
        color: QuranTheme.quranTextSelected(context),
        backgroundColor: _ayahHighlightFill(context),
      );
    }
    return base;
  }

  List<TextSpan> _ayahTextSpans(
    BuildContext context,
    QuranAyah ayah,
    TextStyle? base,
  ) {
    final activeWordIndex = widget.activeWordVerseKey == ayah.verseKey
        ? widget.activeWordIndex
        : null;
    if (activeWordIndex == null) {
      return [
        TextSpan(
          text: '${_cleanArabicText(ayah.text)} ',
          recognizer: _recognizerFor(ayah),
          style: _ayahStyle(context, ayah, base),
        ),
      ];
    }
    final wordHighlight = QuranTheme.wordHighlight(context);
    final ayahSelected =
        ayah.verseKey == widget.activeAudioVerseKey ||
        ayah.verseKey == widget.selectedVerseKey;
    final ayahFill = ayah.verseKey == widget.activeAudioVerseKey
        ? _ayahHighlightFill(context, audioActive: true)
        : ayah.verseKey == widget.selectedVerseKey
        ? _ayahHighlightFill(context)
        : null;
    final inactiveWordColor = ayahSelected
        ? QuranTheme.quranTextSelected(context)
        : QuranTheme.quranTextNormal(context);
    final words = QuranArabicScript.wordSpans(_cleanArabicText(ayah.text));
    return [
      for (var index = 0; index < words.length; index++)
        TextSpan(
          text: index == words.length - 1 ? '${words[index]} ' : words[index],
          recognizer: _recognizerFor(ayah),
          style: base?.copyWith(
            color: index + 1 == activeWordIndex
                ? wordHighlight
                : inactiveWordColor,
            fontWeight: base.fontWeight,
            backgroundColor: ayahFill,
          ),
        ),
    ];
  }

  InlineSpan _anchorSpan(String verseKey) {
    final key = _verseKeys?[verseKey];
    if (key == null) {
      return const TextSpan(text: '');
    }
    return WidgetSpan(
      child: SizedBox(key: key, width: 0, height: 1),
      alignment: PlaceholderAlignment.middle,
    );
  }
}

class _FallbackBookPageText extends StatefulWidget {
  const _FallbackBookPageText({
    super.key,
    required this.ayahs,
    required this.selectedVerseKey,
    required this.activeAudioVerseKey,
    required this.activeWordVerseKey,
    required this.activeWordIndex,
    required this.currentVerseKey,
    required this.arabicFontScale,
    required this.translationFontScale,
    required this.translationsByVerse,
    required this.translationResource,
    required this.onAyahTap,
    required this.selectionEnabled,
    required this.verseKeys,
    required this.arabicScript,
  });

  final List<QuranAyah> ayahs;
  final String? selectedVerseKey;
  final String? activeAudioVerseKey;
  final String? activeWordVerseKey;
  final int? activeWordIndex;
  final String? currentVerseKey;
  final double arabicFontScale;
  final double translationFontScale;
  final Map<String, String> translationsByVerse;
  final QuranTranslationResource? translationResource;
  final ValueChanged<QuranAyah> onAyahTap;
  final bool selectionEnabled;
  final Map<String, GlobalKey>? verseKeys;
  final QuranArabicScript arabicScript;

  @override
  State<_FallbackBookPageText> createState() => _FallbackBookPageTextState();
}

class _FallbackBookPageTextState extends State<_FallbackBookPageText> {
  static const _lineHorizontalPadding = 4.0;
  static const _lineHorizontalInset = _lineHorizontalPadding * 2;

  _FallbackBookLineCacheKey? _cacheKey;
  List<_FallbackBookLine> _cachedLines = const [];

  @override
  Widget build(BuildContext context) {
    final arabicStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontSize: 26 * widget.arabicFontScale,
      fontFamily: widget.arabicScript.fontFamily,
      height: widget.arabicScript.readerLineHeight,
      color: QuranTheme.quranTextNormal(context),
      fontWeight: FontWeight.w700,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaler = MediaQuery.textScalerOf(context);
        final translationStyle = Theme.of(context).textTheme.bodySmall
            ?.copyWith(
              color: QuranTheme.subText(context, 0.66),
              fontSize: 12 * widget.translationFontScale,
              height: 1.22,
              fontWeight: FontWeight.w600,
            );
        final lineWidth = (constraints.maxWidth - _lineHorizontalInset)
            .clamp(0, double.infinity)
            .toDouble();
        final key = _FallbackBookLineCacheKey(
          maxWidth: lineWidth,
          fontSize: arabicStyle?.fontSize ?? 26,
          textScale: textScaler.scale(1),
          ayahCount: widget.ayahs.length,
          ayahHash: Object.hashAll(widget.ayahs),
        );
        if (_cacheKey != key) {
          _cacheKey = key;
          _cachedLines = _FallbackBookLineBuilder.buildLines(
            ayahs: widget.ayahs,
            maxWidth: lineWidth,
            arabicStyle: arabicStyle ?? const TextStyle(fontSize: 26),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final line in _cachedLines)
              _FallbackBookLineView(
                line: line,
                selectedVerseKey: widget.selectedVerseKey,
                activeAudioVerseKey: widget.activeAudioVerseKey,
                activeWordVerseKey: widget.activeWordVerseKey,
                activeWordIndex: widget.activeWordIndex,
                currentVerseKey: widget.currentVerseKey,
                arabicStyle: arabicStyle,
                translationStyle: translationStyle,
                translationsByVerse: widget.translationsByVerse,
                translationResource: widget.translationResource,
                onAyahTap: widget.onAyahTap,
                selectionEnabled: widget.selectionEnabled,
                verseKeys: widget.verseKeys,
              ),
          ],
        );
      },
    );
  }
}

class _FallbackBookLineCacheKey {
  const _FallbackBookLineCacheKey({
    required this.maxWidth,
    required this.fontSize,
    required this.textScale,
    required this.ayahCount,
    required this.ayahHash,
  });

  final double maxWidth;
  final double fontSize;
  final double textScale;
  final int ayahCount;
  final int ayahHash;

  @override
  bool operator ==(Object other) {
    return other is _FallbackBookLineCacheKey &&
        other.maxWidth == maxWidth &&
        other.fontSize == fontSize &&
        other.textScale == textScale &&
        other.ayahCount == ayahCount &&
        other.ayahHash == ayahHash;
  }

  @override
  int get hashCode {
    return Object.hash(maxWidth, fontSize, textScale, ayahCount, ayahHash);
  }
}

class _FallbackBookLineBuilder {
  const _FallbackBookLineBuilder._();

  static List<_FallbackBookLine> buildLines({
    required List<QuranAyah> ayahs,
    required double maxWidth,
    required TextStyle arabicStyle,
  }) {
    final tokens = _tokensFor(ayahs);
    if (tokens.isEmpty) {
      return const [];
    }
    final effectiveWidth = maxWidth.isFinite && maxWidth > 0
        ? maxWidth
        : double.infinity;
    final lines = <_FallbackBookLine>[];
    var current = <_FallbackBookToken>[];
    for (var index = 0; index < tokens.length; index++) {
      final candidate = [...current, tokens[index]];
      if (current.isNotEmpty &&
          !_fitsArabicLine(candidate, effectiveWidth, arabicStyle)) {
        lines.add(_lineFor(current, tokens, effectiveWidth, arabicStyle));
        current = [tokens[index]];
        continue;
      }
      current = candidate;
    }
    if (current.isNotEmpty) {
      lines.add(_lineFor(current, tokens, effectiveWidth, arabicStyle));
    }
    return lines;
  }

  static List<_FallbackBookToken> _tokensFor(List<QuranAyah> ayahs) {
    final tokens = <_FallbackBookToken>[];
    for (final ayah in ayahs) {
      final words = QuranArabicScript.wordSpans(_cleanArabicText(ayah.text));
      for (var index = 0; index < words.length; index++) {
        tokens.add(
          _FallbackBookToken(
            ayah: ayah,
            wordIndex: index + 1,
            arabicText: words[index].trimRight(),
            isAyahEnd: index == words.length - 1,
          ),
        );
      }
    }
    return tokens;
  }

  static bool _fitsArabicLine(
    List<_FallbackBookToken> lineTokens,
    double maxWidth,
    TextStyle arabicStyle,
  ) {
    if (maxWidth == double.infinity) {
      return true;
    }
    final text = _arabicFor(lineTokens);
    return QuranInterlinearLineBuilder._lineWidthForPrepared(
          prepared: QuranInterlinearLineBuilder._prepareArabicLine(
            text,
            arabicStyle,
          ),
          text: text,
          maxWidth: maxWidth,
          arabicStyle: arabicStyle,
        ) <=
        maxWidth + 0.5;
  }

  static _FallbackBookLine _lineFor(
    List<_FallbackBookToken> lineTokens,
    List<_FallbackBookToken> allTokens,
    double maxWidth,
    TextStyle arabicStyle,
  ) {
    final displayArabic = _arabicFor(lineTokens);
    final arabicWidth = _lineWidth(displayArabic, maxWidth, arabicStyle);
    return _FallbackBookLine(
      tokens: List<_FallbackBookToken>.unmodifiable(lineTokens),
      displayArabic: displayArabic,
      arabicWidth: arabicWidth,
      wordSpacing: _wordSpacingFor(
        lineTokens: lineTokens,
        allTokens: allTokens,
        displayArabic: displayArabic,
        arabicWidth: arabicWidth,
        maxWidth: maxWidth,
      ),
    );
  }

  static double _lineWidth(
    String text,
    double maxWidth,
    TextStyle arabicStyle,
  ) {
    if (maxWidth == double.infinity) {
      return 0;
    }
    return QuranInterlinearLineBuilder._lineWidthForPrepared(
      prepared: QuranInterlinearLineBuilder._prepareArabicLine(
        text,
        arabicStyle,
      ),
      text: text,
      maxWidth: maxWidth,
      arabicStyle: arabicStyle,
    );
  }

  static double _wordSpacingFor({
    required List<_FallbackBookToken> lineTokens,
    required List<_FallbackBookToken> allTokens,
    required String displayArabic,
    required double arabicWidth,
    required double maxWidth,
  }) {
    final gapCount = lineTokens.length - 1;
    if (maxWidth == double.infinity || gapCount < 3) {
      return 0;
    }
    if (_isFinalLine(lineTokens, allTokens)) {
      return 0;
    }
    final leftover = maxWidth - arabicWidth;
    if (leftover < 18 || leftover > maxWidth * 0.45) {
      return 0;
    }
    final spaceCount = ' '.allMatches(displayArabic).length;
    if (spaceCount == 0) {
      return 0;
    }
    return (leftover / spaceCount).clamp(0, 4).toDouble();
  }

  static bool _isFinalLine(
    List<_FallbackBookToken> lineTokens,
    List<_FallbackBookToken> allTokens,
  ) {
    if (lineTokens.isEmpty || allTokens.isEmpty) {
      return true;
    }
    final last = lineTokens.last;
    final allLast = allTokens.last;
    return last.verseKey == allLast.verseKey &&
        last.wordIndex == allLast.wordIndex;
  }

  static String _arabicFor(List<_FallbackBookToken> lineTokens) {
    return lineTokens.map(_tokenTextFor).join();
  }

  static String _tokenTextFor(_FallbackBookToken token) {
    final marker = token.isAyahEnd ? ' ﴿${token.ayah.number}﴾ ' : ' ';
    return '${token.arabicText}$marker';
  }
}

class _FallbackBookLine {
  const _FallbackBookLine({
    required this.tokens,
    required this.displayArabic,
    required this.arabicWidth,
    required this.wordSpacing,
  });

  final List<_FallbackBookToken> tokens;
  final String displayArabic;
  final double arabicWidth;
  final double wordSpacing;
}

class _FallbackBookToken {
  const _FallbackBookToken({
    required this.ayah,
    required this.wordIndex,
    required this.arabicText,
    required this.isAyahEnd,
  });

  final QuranAyah ayah;
  final int wordIndex;
  final String arabicText;
  final bool isAyahEnd;

  String get verseKey => ayah.verseKey;
}

class _FallbackBookLineView extends StatefulWidget {
  const _FallbackBookLineView({
    required this.line,
    required this.selectedVerseKey,
    required this.activeAudioVerseKey,
    required this.activeWordVerseKey,
    required this.activeWordIndex,
    required this.currentVerseKey,
    required this.arabicStyle,
    required this.translationStyle,
    required this.translationsByVerse,
    required this.translationResource,
    required this.onAyahTap,
    required this.selectionEnabled,
    required this.verseKeys,
  });

  final _FallbackBookLine line;
  final String? selectedVerseKey;
  final String? activeAudioVerseKey;
  final String? activeWordVerseKey;
  final int? activeWordIndex;
  final String? currentVerseKey;
  final TextStyle? arabicStyle;
  final TextStyle? translationStyle;
  final Map<String, String> translationsByVerse;
  final QuranTranslationResource? translationResource;
  final ValueChanged<QuranAyah> onAyahTap;
  final bool selectionEnabled;
  final Map<String, GlobalKey>? verseKeys;

  @override
  State<_FallbackBookLineView> createState() => _FallbackBookLineViewState();
}

class _FallbackBookLineViewState extends State<_FallbackBookLineView> {
  final _recognizers = <String, TapGestureRecognizer>{};

  @override
  void didUpdateWidget(_FallbackBookLineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.selectionEnabled) {
      _disposeRecognizers();
      return;
    }
    final activeKeys = widget.line.tokens
        .map((token) => token.verseKey)
        .toSet();
    for (final entry in _recognizers.entries.toList()) {
      if (!activeKeys.contains(entry.key)) {
        entry.value.dispose();
        _recognizers.remove(entry.key);
      }
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  TapGestureRecognizer? _recognizerFor(_FallbackBookToken token) {
    if (!widget.selectionEnabled) {
      return null;
    }
    final recognizer = _recognizers.putIfAbsent(
      token.verseKey,
      TapGestureRecognizer.new,
    );
    recognizer.onTap = () => widget.onAyahTap(token.ayah);
    return recognizer;
  }

  @override
  Widget build(BuildContext context) {
    final translation = _translationForLine();
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: RichText(
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.clip,
              text: TextSpan(
                style: _arabicLineStyle(),
                children: [
                  for (final token in widget.line.tokens) ...[
                    if (token.wordIndex == 1) _anchorSpan(token.verseKey),
                    TextSpan(
                      text: _FallbackBookLineBuilder._tokenTextFor(token),
                      recognizer: _recognizerFor(token),
                      style: _tokenStyle(context, token),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (translation.isNotEmpty) ...[
            const SizedBox(height: 2),
            QuranTranslationText(
              text: translation,
              resource: widget.translationResource,
              style: widget.translationStyle,
            ),
          ],
        ],
      ),
    );
  }

  InlineSpan _anchorSpan(String verseKey) {
    final key = widget.verseKeys?[verseKey];
    if (key == null) {
      return const TextSpan(text: '');
    }
    return WidgetSpan(
      child: SizedBox(key: key, width: 0, height: 1),
      alignment: PlaceholderAlignment.middle,
    );
  }

  TextStyle? _arabicLineStyle() {
    return widget.arabicStyle?.copyWith(wordSpacing: widget.line.wordSpacing);
  }

  TextStyle? _tokenStyle(BuildContext context, _FallbackBookToken token) {
    final baseStyle = _arabicLineStyle();
    final wordIsActive =
        widget.activeWordVerseKey == token.verseKey &&
        widget.activeWordIndex == token.wordIndex;
    final wordIsAudioActive = token.verseKey == widget.activeAudioVerseKey;
    final wordIsSelected = token.verseKey == widget.selectedVerseKey;
    final wordIsHighlighted = wordIsAudioActive || wordIsSelected;
    if (wordIsActive) {
      return baseStyle?.copyWith(
        color: QuranTheme.wordHighlight(context),
        backgroundColor: wordIsAudioActive
            ? _ayahHighlightFill(context, audioActive: true)
            : wordIsSelected
            ? _ayahHighlightFill(context)
            : null,
      );
    }
    if (wordIsHighlighted) {
      return baseStyle?.copyWith(
        color: QuranTheme.quranTextSelected(context),
        backgroundColor: wordIsAudioActive
            ? _ayahHighlightFill(context, audioActive: true)
            : _ayahHighlightFill(context),
      );
    }
    return baseStyle;
  }

  String _translationForLine() {
    final endingAyahs = <String, QuranAyah>{};
    for (final token in widget.line.tokens) {
      if (token.isAyahEnd) {
        endingAyahs[token.verseKey] = token.ayah;
      }
    }
    return endingAyahs.values
        .map((ayah) {
          final text =
              widget.translationsByVerse[ayah.verseKey] ?? ayah.translation;
          return _cleanTranslationText(text);
        })
        .where((text) => text.isNotEmpty)
        .join('\n');
  }
}

class InterlinearBookPageText extends StatefulWidget {
  const InterlinearBookPageText({
    super.key,
    required this.words,
    required this.selectedVerseKey,
    required this.activeAudioVerseKey,
    required this.activeWordVerseKey,
    required this.activeWordIndex,
    required this.currentVerseKey,
    required this.arabicFontScale,
    this.translationFontScale = 1,
    required this.onAyahTap,
    this.translationResource,
    this.selectionEnabled = true,
    this.arabicScript = QuranArabicScript.uthmani,
    this.verseKeys,
  });

  final List<QuranWord> words;
  final String? selectedVerseKey;
  final String? activeAudioVerseKey;
  final String? activeWordVerseKey;
  final int? activeWordIndex;
  final String? currentVerseKey;
  final double arabicFontScale;
  final double translationFontScale;
  final void Function(int surahNumber, int ayahNumber) onAyahTap;
  final QuranTranslationResource? translationResource;
  final bool selectionEnabled;
  final QuranArabicScript arabicScript;
  final Map<String, GlobalKey>? verseKeys;

  @override
  State<InterlinearBookPageText> createState() =>
      _InterlinearBookPageTextState();
}

class _InterlinearBookPageTextState extends State<InterlinearBookPageText> {
  static const _lineHorizontalPadding = 4.0;
  static const _lineHorizontalInset = _lineHorizontalPadding * 2;

  _InterlinearLineCacheKey? _cacheKey;
  List<QuranInterlinearLine> _cachedLines = const [];

  @override
  Widget build(BuildContext context) {
    final arabicStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontSize: 26 * widget.arabicFontScale,
      fontFamily: widget.arabicScript.fontFamily,
      height: widget.arabicScript.readerLineHeight,
      color: QuranTheme.quranTextNormal(context),
      fontWeight: FontWeight.w700,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaler = MediaQuery.textScalerOf(context);
        final translationStyle = Theme.of(context).textTheme.bodySmall
            ?.copyWith(
              color: QuranTheme.subText(context, 0.66),
              fontSize: 12 * widget.translationFontScale,
              height: 1.22,
              fontWeight: FontWeight.w600,
            );
        final lineWidth = (constraints.maxWidth - _lineHorizontalInset)
            .clamp(0, double.infinity)
            .toDouble();
        final key = _InterlinearLineCacheKey(
          maxWidth: lineWidth,
          fontSize: arabicStyle?.fontSize ?? 26,
          translationFontSize: translationStyle?.fontSize ?? 12,
          textScale: textScaler.scale(1),
          tokenCount: widget.words.length,
          tokenHash: Object.hashAll(widget.words),
          languageCode: widget.translationResource?.wordTranslationLanguageCode,
        );
        if (_cacheKey != key) {
          _cacheKey = key;
          _cachedLines = QuranInterlinearLineBuilder.buildLines(
            words: widget.words,
            maxWidth: lineWidth,
            arabicStyle: arabicStyle ?? const TextStyle(fontSize: 26),
            textScaler: textScaler,
            requireCompleteTranslation:
                widget.arabicScript == QuranArabicScript.indoPak,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final line in _cachedLines)
              _InterlinearLineView(
                line: line,
                allWords: widget.words,
                selectedVerseKey: widget.selectedVerseKey,
                activeAudioVerseKey: widget.activeAudioVerseKey,
                activeWordVerseKey: widget.activeWordVerseKey,
                activeWordIndex: widget.activeWordIndex,
                currentVerseKey: widget.currentVerseKey,
                arabicStyle: arabicStyle,
                translationStyle: translationStyle,
                translationResource: widget.translationResource,
                onAyahTap: widget.onAyahTap,
                selectionEnabled: widget.selectionEnabled,
                verseKeys: widget.verseKeys,
              ),
          ],
        );
      },
    );
  }
}

class _InterlinearLineCacheKey {
  const _InterlinearLineCacheKey({
    required this.maxWidth,
    required this.fontSize,
    required this.translationFontSize,
    required this.textScale,
    required this.tokenCount,
    required this.tokenHash,
    required this.languageCode,
  });

  final double maxWidth;
  final double fontSize;
  final double translationFontSize;
  final double textScale;
  final int tokenCount;
  final int tokenHash;
  final String? languageCode;

  @override
  bool operator ==(Object other) {
    return other is _InterlinearLineCacheKey &&
        other.maxWidth == maxWidth &&
        other.fontSize == fontSize &&
        other.translationFontSize == translationFontSize &&
        other.textScale == textScale &&
        other.tokenCount == tokenCount &&
        other.tokenHash == tokenHash &&
        other.languageCode == languageCode;
  }

  @override
  int get hashCode {
    return Object.hash(
      maxWidth,
      fontSize,
      translationFontSize,
      textScale,
      tokenCount,
      tokenHash,
      languageCode,
    );
  }
}

class QuranInterlinearLineBuilder {
  const QuranInterlinearLineBuilder._();

  static List<QuranInterlinearLine> buildLines({
    required List<QuranWord> words,
    required double maxWidth,
    required TextStyle arabicStyle,
    TextScaler textScaler = TextScaler.noScaling,
    bool requireCompleteTranslation = false,
  }) {
    if (words.isEmpty) {
      return const [];
    }
    final effectiveWidth = maxWidth.isFinite && maxWidth > 0
        ? maxWidth
        : double.infinity;
    final lines = <QuranInterlinearLine>[];
    var current = <QuranWord>[];
    for (var index = 0; index < words.length; index++) {
      final candidate = [...current, words[index]];
      if (current.isNotEmpty &&
          !_fitsArabicLine(candidate, words, effectiveWidth, arabicStyle)) {
        lines.add(
          _lineFor(
            current,
            words,
            effectiveWidth,
            arabicStyle,
            requireCompleteTranslation,
          ),
        );
        current = [words[index]];
        continue;
      }
      current = candidate;
    }
    if (current.isNotEmpty) {
      lines.add(
        _lineFor(
          current,
          words,
          effectiveWidth,
          arabicStyle,
          requireCompleteTranslation,
        ),
      );
    }
    return lines;
  }

  static bool _fitsArabicLine(
    List<QuranWord> lineWords,
    List<QuranWord> allWords,
    double maxWidth,
    TextStyle arabicStyle,
  ) {
    if (maxWidth == double.infinity) {
      return true;
    }
    final prepared = _prepareArabicLine(
      _arabicFor(lineWords, allWords),
      arabicStyle,
    );
    return _lineWidthForPrepared(
          prepared: prepared,
          text: _arabicFor(lineWords, allWords),
          maxWidth: maxWidth,
          arabicStyle: arabicStyle,
        ) <=
        maxWidth + 0.5;
  }

  static QuranInterlinearLine _lineFor(
    List<QuranWord> lineWords,
    List<QuranWord> allWords,
    double maxWidth,
    TextStyle arabicStyle,
    bool requireCompleteTranslation,
  ) {
    final displayArabic = _arabicFor(lineWords, allWords);
    final arabicWidth = _lineWidth(displayArabic, maxWidth, arabicStyle);
    final gapCount = lineWords.length - 1;
    return QuranInterlinearLine(
      words: List<QuranWord>.unmodifiable(lineWords),
      displayArabic: displayArabic,
      displayTranslation:
          requireCompleteTranslation &&
              lineWords.any((word) => word.translation.trim().isEmpty)
          ? ''
          : _translationFor(lineWords),
      arabicWidth: arabicWidth,
      gapCount: gapCount,
      wordSpacing: _wordSpacingFor(
        lineWords: lineWords,
        allWords: allWords,
        displayArabic: displayArabic,
        arabicWidth: arabicWidth,
        maxWidth: maxWidth,
      ),
    );
  }

  static double _lineWidth(
    String text,
    double maxWidth,
    TextStyle arabicStyle,
  ) {
    if (maxWidth == double.infinity) {
      return 0;
    }
    return _lineWidthForPrepared(
      prepared: _prepareArabicLine(text, arabicStyle),
      text: text,
      maxWidth: maxWidth,
      arabicStyle: arabicStyle,
    );
  }

  static double _lineWidthForPrepared({
    required pretext.PreparedText prepared,
    required String text,
    required double maxWidth,
    required TextStyle arabicStyle,
  }) {
    final pretextWidth = pretext.measureNaturalWidth(prepared);
    final painter = TextPainter(
      text: TextSpan(text: text, style: arabicStyle),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      maxLines: 1,
    )..layout();
    final shapedWidth = painter.width;
    painter.dispose();
    return pretextWidth < shapedWidth ? pretextWidth : shapedWidth;
  }

  static pretext.PreparedText _prepareArabicLine(
    String text,
    TextStyle arabicStyle,
  ) {
    return pretext.prepare(
      text,
      pretext.TextStyleFont(arabicStyle, textDirection: TextDirection.rtl),
      whiteSpace: pretext.WhiteSpaceMode.preWrap,
    );
  }

  static double _wordSpacingFor({
    required List<QuranWord> lineWords,
    required List<QuranWord> allWords,
    required String displayArabic,
    required double arabicWidth,
    required double maxWidth,
  }) {
    final gapCount = lineWords.length - 1;
    if (maxWidth == double.infinity || gapCount < 3) {
      return 0;
    }
    if (_isFinalLine(lineWords, allWords)) {
      return 0;
    }
    final leftover = maxWidth - arabicWidth;
    if (leftover < 18 || leftover > maxWidth * 0.45) {
      return 0;
    }
    final spaceCount = ' '.allMatches(displayArabic).length;
    if (spaceCount == 0) {
      return 0;
    }
    return (leftover / spaceCount).clamp(0, 4).toDouble();
  }

  static bool _isFinalLine(
    List<QuranWord> lineWords,
    List<QuranWord> allWords,
  ) {
    if (lineWords.isEmpty || allWords.isEmpty) {
      return true;
    }
    final last = lineWords.last;
    final allLast = allWords.last;
    return last.verseKey == allLast.verseKey &&
        last.wordIndex == allLast.wordIndex;
  }

  static String _translationFor(List<QuranWord> lineWords) {
    return lineWords
        .map((word) => word.translation)
        .where((text) => text.trim().isNotEmpty)
        .join(' ');
  }

  static String _arabicFor(
    List<QuranWord> lineWords,
    List<QuranWord> allWords,
  ) {
    return lineWords.map((word) => _wordTextFor(word, allWords)).join();
  }

  static String _wordTextFor(QuranWord word, List<QuranWord> allWords) {
    final marker = _isAyahEnd(word, allWords) ? ' ﴿${word.ayahNumber}﴾ ' : ' ';
    return '${word.arabicText}$marker';
  }

  static bool _isAyahEnd(QuranWord word, List<QuranWord> allWords) {
    final index = allWords.indexWhere(
      (candidate) =>
          candidate.verseKey == word.verseKey &&
          candidate.wordIndex == word.wordIndex,
    );
    if (index == -1 || index == allWords.length - 1) {
      return true;
    }
    return allWords[index + 1].verseKey != word.verseKey;
  }
}

class _InterlinearLineView extends StatefulWidget {
  const _InterlinearLineView({
    required this.line,
    required this.allWords,
    required this.selectedVerseKey,
    required this.activeAudioVerseKey,
    required this.activeWordVerseKey,
    required this.activeWordIndex,
    required this.currentVerseKey,
    required this.arabicStyle,
    required this.translationStyle,
    required this.translationResource,
    required this.onAyahTap,
    required this.selectionEnabled,
    required this.verseKeys,
  });

  final QuranInterlinearLine line;
  final List<QuranWord> allWords;
  final String? selectedVerseKey;
  final String? activeAudioVerseKey;
  final String? activeWordVerseKey;
  final int? activeWordIndex;
  final String? currentVerseKey;
  final TextStyle? arabicStyle;
  final TextStyle? translationStyle;
  final QuranTranslationResource? translationResource;
  final void Function(int surahNumber, int ayahNumber) onAyahTap;
  final bool selectionEnabled;
  final Map<String, GlobalKey>? verseKeys;

  @override
  State<_InterlinearLineView> createState() => _InterlinearLineViewState();
}

class _InterlinearLineViewState extends State<_InterlinearLineView> {
  final _recognizers = <String, TapGestureRecognizer>{};

  @override
  void didUpdateWidget(_InterlinearLineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.selectionEnabled) {
      _disposeRecognizers();
      return;
    }
    final activeKeys = widget.line.words.map((word) => word.verseKey).toSet();
    for (final entry in _recognizers.entries.toList()) {
      if (!activeKeys.contains(entry.key)) {
        entry.value.dispose();
        _recognizers.remove(entry.key);
      }
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  TapGestureRecognizer? _recognizerFor(QuranWord word) {
    if (!widget.selectionEnabled) {
      return null;
    }
    final recognizer = _recognizers.putIfAbsent(
      word.verseKey,
      TapGestureRecognizer.new,
    );
    recognizer.onTap = () => widget.onAyahTap(
      _surahNumberFromVerseKey(word.verseKey),
      word.ayahNumber,
    );
    return recognizer;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: RichText(
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.clip,
              text: TextSpan(
                style: _arabicLineStyle(),
                children: [
                  for (final word in widget.line.words) ...[
                    if (word.wordIndex == 1) _anchorSpan(word.verseKey),
                    TextSpan(
                      text: _wordText(word),
                      recognizer: _recognizerFor(word),
                      style: _wordStyle(context, word),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (widget.line.displayTranslation.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            QuranTranslationText(
              text: widget.line.displayTranslation,
              resource: widget.translationResource,
              style: widget.translationStyle,
            ),
          ],
        ],
      ),
    );
  }

  InlineSpan _anchorSpan(String verseKey) {
    final key = widget.verseKeys?[verseKey];
    if (key == null) {
      return const TextSpan(text: '');
    }
    return WidgetSpan(
      child: SizedBox(key: key, width: 0, height: 1),
      alignment: PlaceholderAlignment.middle,
    );
  }

  String _wordText(QuranWord word) {
    return QuranInterlinearLineBuilder._wordTextFor(word, widget.allWords);
  }

  TextStyle? _arabicLineStyle() {
    return widget.arabicStyle?.copyWith(wordSpacing: widget.line.wordSpacing);
  }

  TextStyle? _wordStyle(BuildContext context, QuranWord word) {
    final baseStyle = _arabicLineStyle();
    final wordIsActive =
        widget.activeWordVerseKey == word.verseKey &&
        widget.activeWordIndex == word.wordIndex;
    final wordIsAudioActive = word.verseKey == widget.activeAudioVerseKey;
    final wordIsSelected = word.verseKey == widget.selectedVerseKey;
    final wordIsHighlighted = wordIsAudioActive || wordIsSelected;
    if (wordIsActive) {
      return baseStyle?.copyWith(
        color: QuranTheme.wordHighlight(context),
        backgroundColor: wordIsAudioActive
            ? _ayahHighlightFill(context, audioActive: true)
            : wordIsSelected
            ? _ayahHighlightFill(context)
            : null,
      );
    }
    if (wordIsHighlighted) {
      return baseStyle?.copyWith(
        color: QuranTheme.quranTextSelected(context),
        backgroundColor: wordIsAudioActive
            ? _ayahHighlightFill(context, audioActive: true)
            : _ayahHighlightFill(context),
      );
    }
    return baseStyle;
  }
}

String _cleanArabicText(String value) {
  return QuranArabicScript.cleanUthmaniText(value);
}

String _cleanTranslationText(String value) {
  return value.replaceFirst(RegExp(r'\s*-?\s*﴾\d+﴿\s*$'), '').trim();
}

Color _ayahHighlightFill(BuildContext context, {bool audioActive = false}) {
  final color = audioActive
      ? QuranTheme.wordHighlight(context)
      : Theme.of(context).colorScheme.primary;
  final alpha = QuranTheme.isDark(context)
      ? audioActive
            ? 0.24
            : 0.18
      : audioActive
      ? 0.15
      : 0.13;
  return color.withValues(alpha: alpha);
}

int _surahNumberFromVerseKey(String verseKey) {
  final separator = verseKey.indexOf(':');
  if (separator <= 0) {
    return 1;
  }
  return int.tryParse(verseKey.substring(0, separator)) ?? 1;
}
