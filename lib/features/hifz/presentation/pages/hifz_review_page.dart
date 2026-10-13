import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/widgets/app_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/architectural_backdrop.dart';
import '../../../quran/domain/entities/quran_audio_reciter.dart';
import '../../../quran/domain/entities/quran_ayah.dart';
import '../../../quran/domain/entities/quran_surah.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../../quran_audio/domain/entities/quran_audio_state.dart';
import '../../../quran_audio/presentation/cubit/quran_audio_cubit.dart';
import '../../domain/entities/hifz_models.dart';
import '../../domain/repositories/hifz_repository.dart';

class HifzReviewPage extends StatefulWidget {
  const HifzReviewPage({super.key, required this.collectionId});

  final String collectionId;

  @override
  State<HifzReviewPage> createState() => _HifzReviewPageState();
}

class _HifzReviewPageState extends State<HifzReviewPage> {
  late final HifzRepository _repository;
  late final QuranRepository _quranRepository;
  List<HifzCard> _cards = const [];
  int _index = 0;
  QuranAyah? _ayah;
  QuranSurah? _surah;
  bool _loading = true;
  bool _revealed = false;
  bool _hint = false;
  bool _ratingInProgress = false;
  String? _error;
  QuranAudioCubit? _audioCubit;

  @override
  void initState() {
    super.initState();
    _repository = getIt<HifzRepository>();
    _quranRepository = getIt<QuranRepository>();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audioCubit ??= context.read<QuranAudioCubit>();
  }

  @override
  void dispose() {
    final audio = _audioCubit;
    if (audio != null) {
      unawaited(audio.setRepeatMode(QuranAudioRepeatMode.off));
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      _cards = await _repository.dueCardsForCollection(widget.collectionId);
      await _loadCurrentAyah();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Review session could not be loaded.';
        });
      }
    }
  }

  Future<void> _loadCurrentAyah() async {
    if (_index >= _cards.length) {
      if (mounted) {
        setState(() {
          _loading = false;
          _ayah = null;
          _surah = null;
        });
      }
      return;
    }
    final parts = _cards[_index].verseKey.split(':');
    final surahNumber = int.tryParse(parts.first) ?? 1;
    final ayahNumber = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 1;
    final surah = await _quranRepository.getSurah(surahNumber);
    final ayahs = await _quranRepository.getAyahs(surahNumber);
    QuranAyah? ayah;
    for (final item in ayahs) {
      if (item.number == ayahNumber) {
        ayah = item;
        break;
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _surah = surah;
      _ayah = ayah;
      _revealed = false;
      _hint = false;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hifz review'),
        flexibleSpace: const ArchitecturalBackdrop(),
        actions: [
          if (_cards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${(_index + 1).clamp(1, _cards.length)}/${_cards.length}',
              ),
            ),
        ],
      ),
      body: _loading
          ? const AppLoadingView(label: 'Preparing review')
          : _error != null
          ? AppErrorView(
              title: 'Review unavailable',
              message: _error!,
              onRetry: _load,
            )
          : _ayah == null
          ? _ReviewComplete(reviewedCount: _cards.length)
          : _reviewBody(context),
    );
  }

  Widget _reviewBody(BuildContext context) {
    final ayah = _ayah!;
    final firstWord = ayah.text.trim().split(RegExp(r'\s+')).first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${_surah?.englishName ?? 'Surah'} • Ayah ${ayah.number}',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _revealed
                    ? Text(
                        ayah.text,
                        key: const ValueKey('revealed'),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(height: 2, fontWeight: FontWeight.w700),
                      )
                    : ConstrainedBox(
                        key: const ValueKey('hidden'),
                        constraints: const BoxConstraints(minHeight: 180),
                        child: Center(
                          child: Text(
                            _hint ? firstWord : 'Recite from memory',
                            textAlign: TextAlign.center,
                            textDirection: _hint ? TextDirection.rtl : null,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: QuranTheme.subText(context)),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _hint = true),
                    icon: const AppIcon(Icons.lightbulb_outline_rounded),
                    label: const Text('First word'),
                  ),
                  FilledButton.icon(
                    onPressed: () => setState(() => _revealed = true),
                    icon: const AppIcon(Icons.visibility_rounded),
                    label: const Text('Reveal'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _playRepeated,
                icon: const AppIcon(Icons.repeat_rounded),
                label: const Text('Play 3 times'),
              ),
            ],
          ),
        ),
        if (_revealed) ...[
          const SizedBox(height: 14),
          Text(
            'How well did you recall it?',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _RatingButton(
                label: 'Again',
                onTap: () => _rate(HifzReviewRating.again),
              ),
              _RatingButton(
                label: 'Hard',
                onTap: () => _rate(HifzReviewRating.hard),
              ),
              _RatingButton(
                label: 'Good',
                onTap: () => _rate(HifzReviewRating.good),
              ),
              _RatingButton(
                label: 'Easy',
                onTap: () => _rate(HifzReviewRating.easy),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _playRepeated() async {
    final ayah = _ayah;
    final surah = _surah;
    if (ayah == null || surah == null) {
      return;
    }
    final reciters = await _quranRepository.getAudioReciters();
    final savedId = await _quranRepository.getSelectedAudioReciterId();
    QuranAudioReciter? reciter;
    for (final item in reciters) {
      if (!item.isTranslation && item.id == savedId) {
        reciter = item;
        break;
      }
    }
    reciter ??= reciters.where((item) => !item.isTranslation).firstOrNull;
    if (reciter == null || !mounted) {
      return;
    }
    final audio = context.read<QuranAudioCubit>();
    await audio.setRepeatMode(QuranAudioRepeatMode.ayah);
    audio.setRepeatCount(3);
    await audio.playAyah(ayah: ayah, surah: surah, reciter: reciter);
  }

  Future<void> _rate(HifzReviewRating rating) async {
    if (_ratingInProgress || _loading || _index >= _cards.length) return;
    _ratingInProgress = true;
    final index = _index;
    try {
      await _repository.reviewCard(
        verseKey: _cards[index].verseKey,
        rating: rating,
      );
      if (!mounted || index != _index) return;
      setState(() {
        _index++;
        _loading = true;
      });
      await _loadCurrentAyah();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save review. Please try again.'),
          ),
        );
      }
    } finally {
      _ratingInProgress = false;
    }
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onTap, child: Text(label));
  }
}

class _ReviewComplete extends StatelessWidget {
  const _ReviewComplete({required this.reviewedCount});

  final int reviewedCount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              Icons.check_circle_rounded,
              size: 58,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              reviewedCount == 0 ? 'Nothing due' : 'Review complete',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text('$reviewedCount verses reviewed'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    for (final item in this) {
      return item;
    }
    return null;
  }
}
