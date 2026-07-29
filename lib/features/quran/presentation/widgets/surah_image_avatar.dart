import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../data/services/surah_cover_cache.dart';
import '../../domain/entities/surah_image_catalog.dart';

class SurahImageAvatar extends StatefulWidget {
  const SurahImageAvatar({
    super.key,
    required this.surahNumber,
    required this.active,
    required this.fallbackLabel,
    this.size = 42,
  });

  final int surahNumber;
  final bool active;
  final String fallbackLabel;
  final double size;

  @override
  State<SurahImageAvatar> createState() => _SurahImageAvatarState();
}

class _SurahImageAvatarState extends State<SurahImageAvatar> {
  int? _precachedSurah;
  int _loadToken = 0;
  File? _cachedFile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precache();
  }

  @override
  void didUpdateWidget(covariant SurahImageAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surahNumber != widget.surahNumber) {
      _precache();
    }
  }

  void _precache() {
    if (_precachedSurah == widget.surahNumber) {
      return;
    }
    _precachedSurah = widget.surahNumber;
    _cachedFile = null;
    _loadCachedCover();
  }

  Future<void> _loadCachedCover() async {
    final token = ++_loadToken;
    final file = await SurahCoverCache.instance.fileFor(widget.surahNumber);
    if (!mounted || token != _loadToken || file == null) {
      return;
    }
    await precacheImage(FileImage(file), context, onError: (_, _) {});
    if (!mounted || token != _loadToken) {
      return;
    }
    setState(() {
      _cachedFile = file;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final imageUrl = SurahImageCatalog.imageUrlFor(widget.surahNumber);
    final cachedFile = _cachedFile;
    return Semantics(
      image: true,
      label: 'Surah ${widget.surahNumber} image',
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.active ? primary : QuranTheme.outline(context),
            width: widget.active ? 2 : 1,
          ),
        ),
        child: ClipOval(
          child: cachedFile == null
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _SurahImageFallbackBubble(
                      label: widget.fallbackLabel,
                      active: widget.active,
                    );
                  },
                )
              : Image.file(
                  cachedFile,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _SurahImageFallbackBubble(
                      label: widget.fallbackLabel,
                      active: widget.active,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _SurahImageFallbackBubble extends StatelessWidget {
  const _SurahImageFallbackBubble({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ColoredBox(
      color: active ? primary : QuranTheme.softFill(context, primary),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: active ? Colors.white : primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
