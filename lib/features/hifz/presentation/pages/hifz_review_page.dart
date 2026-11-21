import '../../../../core/widgets/app_page_app_bar.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/header_pattern_backdrop.dart';
import '../../../../core/widgets/premium_surface.dart';
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
  bool _preparingAudio = false;
  bool _sessionAudio = false;
  String? _audioError;
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
    if (audio != null && _sessionAudio) {
      _sessionAudio = false;
      unawaited(_releaseSessionAudio(audio));
    }
    super.dispose();
  }

  Future<void> _releaseSessionAudio(QuranAudioCubit audio) async {
    try {
      await audio.stop();
    } catch (_) {}
    try {
      await audio.setRepeatMode(QuranAudioRepeatMode.off);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cards = await _repository.dueCardsForCollection(
        widget.collectionId,
      );
      if (!mounted) return;
      _cards = cards;
      _index = 0;
      await _loadCurrentAyah();
    } catch (_) {
      _loadError();
    }
  }

  void _loadError() {
    if (mounted) {
      setState(() {
        _loading = false;
        _error =
            'Your progress is saved. This review could not be loaded. Please try again.';
      });
    }
  }

  Future<void> _retry() async {
    if (_cards.isEmpty) {
      await _load();
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _loadCurrentAyah();
    } catch (_) {
      _loadError();
    }
  }

  Future<void> _loadCurrentAyah() async {
    if (_index >= _cards.length) {
      if (mounted) {
        setState(() {
          _loading = false;
          _ayah = null;
          _surah = null;
          _error = null;
        });
      }
      return;
    }
    final parts = _cards[_index].verseKey.split(':');
    final surahNumber = int.tryParse(parts.first);
    final ayahNumber = int.tryParse(parts.length > 1 ? parts[1] : '');
    if (surahNumber == null || ayahNumber == null) {
      throw StateError('Invalid ayah');
    }
    final surah = await _quranRepository.getSurah(surahNumber);
    final ayahs = await _quranRepository.getAyahs(surahNumber);
    final ayah = ayahs.where((item) => item.number == ayahNumber).firstOrNull;
    if (ayah == null) throw StateError('Ayah unavailable');
    if (!mounted) return;
    setState(() {
      _surah = surah;
      _ayah = ayah;
      _revealed = false;
      _hint = false;
      _audioError = null;
      _loading = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_ratingInProgress && !_preparingAudio,
    child: Scaffold(
      appBar: AppPageAppBar(
        title: const Text('Memorization review'),
        flexibleSpace: const HeaderPatternBackdrop(),
      ),
      body: _loading
          ? const AppLoadingView(label: 'Preparing your ayah')
          : _error != null
          ? AppErrorView(
              title: 'Could not load this review',
              message: _error!,
              onRetry: _retry,
            )
          : _ayah == null
          ? _ReviewComplete(reviewedCount: _index)
          : _reviewBody(context),
    ),
  );

  Widget _reviewBody(BuildContext context) {
    final ayah = _ayah!;
    final firstWord = ayah.text.trim().split(RegExp(r'\s+')).first;
    final busy = _ratingInProgress || _preparingAudio;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Ayah ${_index + 1} of ${_cards.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: QuranTheme.subText(context),
                ),
              ),
            ),
            Text(
              '$_index reviewed',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: QuranTheme.subText(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: _index / _cards.length,
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ReviewStep(number: '1', label: 'Recite', active: !_revealed),
            _ReviewStep(number: '2', label: 'Check', active: _revealed),
            _ReviewStep(number: '3', label: 'Rate', active: _revealed),
          ],
        ),
        const SizedBox(height: 18),
        PremiumSurface(
          radius: 12,
          borderColor: QuranTheme.outline(context),
          borderWidth: 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _surah?.englishName ?? 'Surah',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Ayah ${ayah.number}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: QuranTheme.subText(context),
                ),
              ),
              const SizedBox(height: 22),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _revealed
                    ? Text(
                        ayah.text,
                        key: const ValueKey('revealed'),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(height: 2, fontWeight: FontWeight.w600),
                      )
                    : ConstrainedBox(
                        key: const ValueKey('hidden'),
                        constraints: const BoxConstraints(minHeight: 150),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _hint ? firstWord : 'Try reciting from memory',
                                textAlign: TextAlign.center,
                                textDirection: _hint ? TextDirection.rtl : null,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: QuranTheme.text(context),
                                      height: _hint ? 2 : 1.4,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _hint
                                    ? 'Here is the first word. Continue at your own pace.'
                                    : 'Take your time. Use a hint whenever you need one.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: QuranTheme.subText(context),
                                      height: 1.5,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              if (!_revealed) ...[
                FilledButton.icon(
                  onPressed: busy
                      ? null
                      : () => setState(() => _revealed = true),
                  icon: const AppIcon(Icons.visibility_outlined, size: 19),
                  label: const Text('Show ayah & check'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: busy || _hint
                      ? null
                      : () => setState(() => _hint = true),
                  icon: const AppIcon(
                    Icons.lightbulb_outline_rounded,
                    size: 18,
                  ),
                  label: Text(_hint ? 'Hint shown' : 'Show first-word hint'),
                ),
              ] else
                Text(
                  'Compare it with what you recited, then choose a rating below.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: QuranTheme.subText(context),
                    height: 1.5,
                  ),
                ),
              const SizedBox(height: 8),
              BlocConsumer<QuranAudioCubit, QuranAudioState>(
                listenWhen: (previous, current) =>
                    previous.errorMessage != current.errorMessage ||
                    (previous.status != QuranAudioStatus.failure &&
                        current.status == QuranAudioStatus.failure),
                listener: (context, audioState) {
                  if (_sessionAudio &&
                      (audioState.errorMessage != null ||
                          audioState.status == QuranAudioStatus.failure)) {
                    setState(() {
                      _audioError =
                          audioState.errorMessage ??
                          'Could not play this ayah. Please try again.';
                    });
                  }
                },
                builder: (context, audioState) {
                  final listening = _sessionAudio && audioState.canPause;
                  return TextButton.icon(
                    onPressed: busy
                        ? null
                        : listening
                        ? _stopListening
                        : _playRepeated,
                    icon: AppIcon(
                      listening ? Icons.stop_rounded : Icons.volume_up_outlined,
                      size: 19,
                    ),
                    label: Text(
                      _preparingAudio
                          ? 'Preparing audio…'
                          : listening
                          ? 'Stop listening'
                          : 'Listen 3 times',
                    ),
                  );
                },
              ),
              if (_audioError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _audioError!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_revealed) ...[
          const SizedBox(height: 24),
          Text(
            'How did it feel?',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Your answer helps schedule the next review.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: QuranTheme.subText(context)),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth < 280
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _RatingButton(
                    width: width,
                    label: 'Again',
                    description: 'I need more practice',
                    onTap: busy ? null : () => _rate(HifzReviewRating.again),
                  ),
                  _RatingButton(
                    width: width,
                    label: 'Hard',
                    description: 'I needed a little help',
                    onTap: busy ? null : () => _rate(HifzReviewRating.hard),
                  ),
                  _RatingButton(
                    width: width,
                    label: 'Good',
                    description: 'I recalled it correctly',
                    onTap: busy ? null : () => _rate(HifzReviewRating.good),
                  ),
                  _RatingButton(
                    width: width,
                    label: 'Easy',
                    description: 'I recalled it confidently',
                    onTap: busy ? null : () => _rate(HifzReviewRating.easy),
                  ),
                ],
              );
            },
          ),
          if (_ratingInProgress)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(child: Text('Saving your review…')),
            ),
        ],
      ],
    );
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _stopListening() async {
    try {
      await _audioCubit?.stop();
      if (mounted) {
        setState(() {
          _sessionAudio = false;
          _audioError = null;
        });
      }
    } catch (_) {
      _message('Could not stop audio. Please try again.');
    }
  }

  Future<void> _playRepeated() async {
    final ayah = _ayah;
    final surah = _surah;
    if (_preparingAudio || _ratingInProgress || ayah == null || surah == null) {
      return;
    }
    setState(() {
      _preparingAudio = true;
      _audioError = null;
    });
    try {
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
      if (!mounted) return;
      if (reciter == null) {
        _message('No recitation is available right now.');
        return;
      }
      final audio = _audioCubit!;
      await audio.setRepeatMode(QuranAudioRepeatMode.ayah);
      if (!mounted) {
        await audio.setRepeatMode(QuranAudioRepeatMode.off);
        return;
      }
      audio.setRepeatCount(3);
      _sessionAudio = true;
      await audio.playAyah(ayah: ayah, surah: surah, reciter: reciter);
      if (!mounted) {
        if (_sessionAudio) {
          _sessionAudio = false;
          await _releaseSessionAudio(audio);
        }
        return;
      }
      if (audio.state.errorMessage != null ||
          audio.state.status == QuranAudioStatus.failure) {
        setState(() {
          _audioError =
              audio.state.errorMessage ??
              'Could not play this ayah. Please try again.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _audioError = 'Could not play this ayah. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _preparingAudio = false);
    }
  }

  Future<void> _rate(HifzReviewRating rating) async {
    if (_ratingInProgress ||
        _preparingAudio ||
        _loading ||
        _index >= _cards.length) {
      return;
    }
    setState(() => _ratingInProgress = true);
    try {
      await _repository.reviewCard(
        verseKey: _cards[_index].verseKey,
        rating: rating,
      );
    } catch (_) {
      _message('Could not save your review. Please try again.');
      if (mounted) setState(() => _ratingInProgress = false);
      return;
    }
    if (!mounted) return;
    if (_sessionAudio) await _stopListening();
    if (!mounted) return;
    setState(() {
      _index++;
      _loading = true;
      _ratingInProgress = false;
    });
    try {
      await _loadCurrentAyah();
    } catch (_) {
      _loadError();
    }
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.number,
    required this.label,
    required this.active,
  });
  final String number;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: active ? QuranTheme.text(context) : QuranTheme.surface(context),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: QuranTheme.outline(context), width: 0.8),
    ),
    child: Text(
      '$number  $label',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: active
            ? QuranTheme.surface(context)
            : QuranTheme.subText(context),
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.width,
    required this.label,
    required this.description,
    required this.onTap,
  });
  final double width;
  final String label;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(14),
        alignment: AlignmentDirectional.centerStart,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: QuranTheme.subText(context),
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ReviewComplete extends StatelessWidget {
  const _ReviewComplete({required this.reviewedCount});
  final int reviewedCount;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: PremiumSurface(
        radius: 12,
        borderColor: QuranTheme.outline(context),
        borderWidth: 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppIcon(Icons.check_circle_outline_rounded, size: 42),
            const SizedBox(height: 18),
            Text(
              reviewedCount == 0 ? 'All caught up' : 'Review complete',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              reviewedCount == 0
                  ? 'No ayahs are due in this collection right now. Come back when your next review is ready.'
                  : '$reviewedCount ${reviewedCount == 1 ? 'ayah' : 'ayahs'} reviewed. Your progress is saved and your next reviews are scheduled.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: QuranTheme.subText(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to memorization'),
            ),
          ],
        ),
      ),
    ),
  );
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    for (final item in this) {
      return item;
    }
    return null;
  }
}
