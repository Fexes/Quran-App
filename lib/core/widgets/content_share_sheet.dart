import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'animated_expansion.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/di/injection.dart';
import '../../features/prayer_times/domain/entities/prayer_banner_phase.dart';
import '../../features/quran/domain/entities/quran_translation.dart';
import '../../features/quran/presentation/widgets/quran_translation_text.dart';
import '../constants/quran_arabic_script.dart';
import '../storage/settings_store.dart';
import '../theme/quran_theme.dart';
import 'app_icon.dart';
import 'app_sheet.dart';
import 'architectural_backdrop.dart';

typedef ContentShareTranslationPickerBuilder =
    Widget Function(
      QuranTranslationResource? resource,
      String? languageCode,
      bool enabled,
      void Function(
        QuranTranslationResource? resource,
        String text,
        String? languageCode,
      )
      onChanged,
      ValueChanged<bool> onLoadingChanged,
    );

Future<void> showContentShareSheet(BuildContext context, Widget sheet) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );

class ContentShareSheet extends StatefulWidget {
  const ContentShareSheet({
    super.key,
    required this.title,
    required this.heading,
    required this.arabicText,
    required this.script,
    required this.translation,
    required this.referenceTitle,
    required this.referenceSubtitle,
    required this.fileName,
    this.translationResource,
    this.translationLanguageCode,
    this.translationPickerBuilder,
    this.transliteration = '',
    this.initialIncludeTransliteration = false,
    this.referenceLabel = 'Reference',
    this.initialIncludeTranslation = true,
  });

  final String title;
  final String heading;
  final String arabicText;
  final QuranArabicScript script;
  final String translation;
  final String referenceTitle;
  final String referenceSubtitle;
  final String referenceLabel;
  final String fileName;
  final QuranTranslationResource? translationResource;
  final String? translationLanguageCode;
  final ContentShareTranslationPickerBuilder? translationPickerBuilder;
  final String transliteration;
  final bool initialIncludeTransliteration;
  final bool initialIncludeTranslation;

  @override
  State<ContentShareSheet> createState() => _ContentShareSheetState();
}

class _ContentShareSheetState extends State<ContentShareSheet> {
  static final _backgroundImages = [
    ArchitecturalBackdrop.assetPath,
    for (final phase in PrayerBannerPhase.values) phase.assetPath,
  ];
  static int _lastBackgroundIndex = -1;

  final _artworkKey = GlobalKey();
  late int _backgroundIndex = _nextBackgroundIndex();
  late String _translation = widget.translation;
  late QuranTranslationResource? _translationResource =
      widget.translationResource;
  late String? _translationLanguageCode = widget.translationLanguageCode;
  late bool _includeArabic = widget.arabicText.trim().isNotEmpty;
  late bool _includeTranslation =
      _hasTranslation && (widget.initialIncludeTranslation || !_includeArabic);
  late bool _includeTransliteration =
      widget.initialIncludeTransliteration && widget.transliteration.isNotEmpty;
  bool _includeReference = true;
  bool _includeBackground = true;
  bool _sharing = false;
  bool _loadingTranslation = false;
  String? _error;

  bool get _hasTranslation => _translation.trim().isNotEmpty;

  int _nextBackgroundIndex() {
    final store = getIt.isRegistered<SettingsStore>()
        ? getIt<SettingsStore>()
        : null;
    if (_lastBackgroundIndex < 0) {
      _lastBackgroundIndex = _backgroundImages.indexOf(
        store?.lastVerseShareBackgroundImage ?? '',
      );
    }
    _lastBackgroundIndex =
        (_lastBackgroundIndex + 1) % _backgroundImages.length;
    if (store != null) {
      unawaited(
        store
            .setLastVerseShareBackgroundImage(
              _backgroundImages[_lastBackgroundIndex],
            )
            .catchError((Object error) {
              debugPrint('Share background choice could not be saved: $error');
            }),
      );
    }
    return _lastBackgroundIndex;
  }

  Future<void> _shareImage(BuildContext buttonContext) async {
    if (_sharing || _loadingTranslation) return;
    final box = buttonContext.findRenderObject();
    final origin = box is RenderBox && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    setState(() {
      _sharing = true;
      _error = null;
    });
    ui.Image? image;
    try {
      if (_includeBackground) {
        await precacheImage(
          AssetImage(_backgroundImages[_backgroundIndex]),
          context,
          onError: (_, _) {},
        );
      }
      // Capture the latest toggles only after their full artwork has painted.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final boundary = _artworkKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary || !boundary.hasSize) {
        throw StateError('The image is not ready.');
      }
      image = await boundary.toImage(
        // Long texts stay complete without creating an oversized bitmap.
        pixelRatio: math.min(3.0, 4096 / boundary.size.longestSide),
      );
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Could not encode the image.');
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          title: widget.title,
          files: [
            XFile.fromData(
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
              mimeType: 'image/png',
            ),
          ],
          fileNameOverrides: [widget.fileName],
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to share the image. Please try again.');
      }
    } finally {
      image?.dispose();
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 280,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: QuranTheme.surfaceVariant(context),
              borderRadius: BorderRadius.circular(QuranTheme.radiusCard),
            ),
            child: FittedBox(
              fit: BoxFit.contain,
              child: RepaintBoundary(
                key: _artworkKey,
                child: MediaQuery.withNoTextScaling(
                  child: SizedBox(
                    width: 360,
                    child: _ContentArtwork(
                      heading: widget.heading,
                      arabicText: widget.arabicText,
                      translation: _translation,
                      translationResource: _translationResource,
                      translationLanguageCode: _translationLanguageCode,
                      transliteration: _includeTransliteration
                          ? widget.transliteration
                          : '',
                      referenceTitle: widget.referenceTitle,
                      referenceSubtitle: widget.referenceSubtitle,
                      script: widget.script,
                      includeArabic: _includeArabic,
                      includeTranslation: _includeTranslation,
                      includeReference: _includeReference,
                      includeBackground: _includeBackground,
                      backgroundImage: _backgroundImages[_backgroundIndex],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Arabic'),
            value: _includeArabic,
            onChanged:
                _sharing ||
                    !_includeTranslation ||
                    widget.arabicText.trim().isEmpty
                ? null
                : (value) => setState(() => _includeArabic = value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Translation'),
            subtitle: _hasTranslation
                ? null
                : const Text('No translation available'),
            value: _includeTranslation,
            onChanged: _sharing || !_hasTranslation || !_includeArabic
                ? null
                : (value) => setState(() => _includeTranslation = value),
          ),
          if (widget.translationPickerBuilder case final builder?)
            builder(
              _translationResource,
              _translationLanguageCode,
              !_sharing,
              (resource, text, languageCode) => setState(() {
                _translation = text;
                _translationResource = resource;
                _translationLanguageCode = languageCode;
                _includeTranslation = true;
              }),
              (value) => setState(() => _loadingTranslation = value),
            ),
          if (widget.transliteration.isNotEmpty)
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Transliteration'),
              value: _includeTransliteration,
              onChanged: _sharing
                  ? null
                  : (value) => setState(() => _includeTransliteration = value),
            ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(widget.referenceLabel),
            value: _includeReference,
            onChanged: _sharing
                ? null
                : (value) => setState(() => _includeReference = value),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Background image'),
            value: _includeBackground,
            onChanged: _sharing
                ? null
                : (value) => setState(() => _includeBackground = value),
          ),
          AnimatedExpansion(
            expanded: _includeBackground,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _sharing
                    ? null
                    : () => setState(() {
                        _backgroundIndex = _nextBackgroundIndex();
                      }),
                icon: const AppIcon(Icons.refresh_rounded, size: 18),
                label: const Text('Change image'),
              ),
            ),
          ),
          AnimatedExpansion(
            expanded: _error != null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _error ?? '',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (buttonContext) => FilledButton.icon(
              onPressed:
                  _sharing ||
                      _loadingTranslation ||
                      (!_includeArabic && !_includeTranslation)
                  ? null
                  : () => _shareImage(buttonContext),
              icon: _sharing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const AppIcon(Icons.ios_share_rounded, size: 20),
              label: Text(_sharing ? 'Creating image...' : 'Share image'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentArtwork extends StatelessWidget {
  const _ContentArtwork({
    required this.heading,
    required this.arabicText,
    required this.translation,
    required this.translationResource,
    required this.translationLanguageCode,
    required this.transliteration,
    required this.referenceTitle,
    required this.referenceSubtitle,
    required this.script,
    required this.includeArabic,
    required this.includeTranslation,
    required this.includeReference,
    required this.includeBackground,
    required this.backgroundImage,
  });

  final String heading;
  final String arabicText;
  final String translation;
  final QuranTranslationResource? translationResource;
  final String? translationLanguageCode;
  final String transliteration;
  final String referenceTitle;
  final String referenceSubtitle;
  final QuranArabicScript script;
  final bool includeArabic;
  final bool includeTranslation;
  final bool includeReference;
  final bool includeBackground;
  final String backgroundImage;

  static const _ink = Color(0xFF193C34);
  static const _gold = Color(0xFF967849);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _ink,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _gold, width: 0.8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (includeBackground)
                SizedBox(
                  height: 152,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        backgroundImage,
                        fit: BoxFit.cover,
                        alignment: Alignment.centerRight,
                        filterQuality: FilterQuality.high,
                        gaplessPlayback: true,
                        excludeFromSemantics: true,
                        errorBuilder: (_, _, _) =>
                            const ColoredBox(color: _ink),
                      ),
                      const ColoredBox(color: Color(0x8C000000)),
                      Positioned(
                        left: 22,
                        top: 20,
                        child: Text(
                          heading,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!includeBackground) ...[
                      Text(
                        heading,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                          color: _gold,
                        ),
                      ),
                      const SizedBox(height: 26),
                    ],
                    if (includeArabic)
                      Text(
                        arabicText,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: script.fontFamily ?? 'NotoSansArabic',
                          fontFamilyFallback: const ['NotoSansArabic'],
                          fontSize: 28,
                          height: 1.9,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                          color: _ink,
                        ),
                      ),
                    if (transliteration.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        transliteration,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          height: 1.7,
                          color: Color(0xFF3D4844),
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                    if ((includeArabic || transliteration.isNotEmpty) &&
                        includeTranslation)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 22),
                        child: Center(
                          child: SizedBox(
                            width: 38,
                            child: Divider(color: _gold, height: 1),
                          ),
                        ),
                      ),
                    if (includeTranslation) ...[
                      QuranTranslationText(
                        text: translation,
                        resource: translationResource,
                        languageCode: translationLanguageCode,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontFamilyFallback: ['NotoSansArabic'],
                          fontSize: 15,
                          height: 1.7,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                          color: Color(0xFF3D4844),
                        ),
                      ),
                    ],
                    if (includeReference) ...[
                      const SizedBox(height: 26),
                      const Divider(color: Color(0xFFDDE4DF), height: 1),
                      const SizedBox(height: 18),
                      Text(
                        referenceTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        referenceSubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 10,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                          color: _gold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
