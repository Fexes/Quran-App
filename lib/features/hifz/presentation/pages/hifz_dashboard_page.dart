import '../../../../core/widgets/app_page_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/utils/parse_localized_int.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/header_pattern_backdrop.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../quran/domain/entities/quran_surah.dart';
import '../../../quran/domain/repositories/quran_repository.dart';
import '../../domain/entities/hifz_models.dart';
import '../../domain/repositories/hifz_repository.dart';
import '../cubit/hifz_dashboard_cubit.dart';
import '../cubit/hifz_dashboard_state.dart';

class HifzDashboardPage extends StatelessWidget {
  const HifzDashboardPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => HifzDashboardCubit(
      repository: getIt<HifzRepository>(),
      quranRepository: getIt<QuranRepository>(),
    )..load(),
    child: const _HifzDashboardView(),
  );
}

class _HifzDashboardView extends StatefulWidget {
  const _HifzDashboardView();

  @override
  State<_HifzDashboardView> createState() => _HifzDashboardViewState();
}

class _HifzDashboardViewState extends State<_HifzDashboardView> {
  bool _creating = false;
  bool _reviewing = false;

  Future<void> _createCollection(BuildContext context) async {
    if (_creating) return;
    _creating = true;
    final cubit = context.read<HifzDashboardCubit>();
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (_) => _CreateCollectionSheet(cubit: cubit),
      );
    } finally {
      _creating = false;
    }
  }

  Future<void> _review(BuildContext context, String id) async {
    if (_reviewing) return;
    _reviewing = true;
    final cubit = context.read<HifzDashboardCubit>();
    try {
      await context.push(AppRoutes.hifzReviewPath(id));
      if (!cubit.isClosed) await cubit.load();
    } finally {
      _reviewing = false;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppPageAppBar(
      title: Text(AppLocalizations.of(context).hifzDashboardTitle),
      flexibleSpace: const HeaderPatternBackdrop(),
      actions: [
        IconButton(
          tooltip: 'New collection',
          onPressed: () => _createCollection(context),
          icon: const AppIcon(Icons.add_rounded),
        ),
      ],
    ),
    body: BlocBuilder<HifzDashboardCubit, HifzDashboardState>(
      builder: (context, state) {
        final dashboard = state.dashboard;
        if (dashboard == null && state.status == HifzDashboardStatus.loading) {
          return const AppLoadingView(label: 'Loading your memorization');
        }
        if (dashboard == null) {
          return AppErrorView(
            title: 'Could not load your progress',
            message: state.errorMessage ?? 'Please try again.',
            onRetry: context.read<HifzDashboardCubit>().load,
          );
        }
        HifzCollection? nextCollection;
        final now = DateTime.now();
        for (final collection in dashboard.collections) {
          if (collection.verseKeys.any(
            (key) => dashboard.cards[key]?.isDue(now) == true,
          )) {
            nextCollection = collection;
            break;
          }
        }
        final next = nextCollection;
        return RefreshIndicator(
          onRefresh: context.read<HifzDashboardCubit>().load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              if (state.status == HifzDashboardStatus.loading) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 12),
              ],
              if (state.errorMessage != null) ...[
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                TextButton(
                  onPressed: context.read<HifzDashboardCubit>().load,
                  child: const Text('Try again'),
                ),
              ],
              _DailyReviewCard(
                dashboard: dashboard,
                nextCollection: next,
                onReview: next == null ? null : () => _review(context, next.id),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Your collections',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _createCollection(context),
                    icon: const AppIcon(Icons.add_rounded, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              Text(
                'Choose a few ayahs. Review them regularly, at your own pace.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: QuranTheme.subText(context),
                ),
              ),
              const SizedBox(height: 14),
              if (dashboard.collections.isEmpty)
                _FirstCollectionCard(
                  onCreate: () => _createCollection(context),
                ),
              for (final collection in dashboard.collections) ...[
                _CollectionCard(
                  key: ValueKey(collection.id),
                  collection: collection,
                  dashboard: dashboard,
                  now: now,
                  onReview: () => _review(context, collection.id),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    ),
  );
}

class _DailyReviewCard extends StatelessWidget {
  const _DailyReviewCard({
    required this.dashboard,
    required this.nextCollection,
    required this.onReview,
  });
  final HifzDashboard dashboard;
  final HifzCollection? nextCollection;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final total = dashboard.cards.length;
    final due = dashboard.dueCards.length;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'DAILY REVIEW',
            style: TextStyle(fontSize: 11, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          Text(
            total == 0
                ? 'A little each day'
                : due == 0
                ? 'You are all caught up'
                : '$due ${due == 1 ? 'ayah' : 'ayahs'} ready to review',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            total == 0
                ? 'Build your memorization one small collection at a time.'
                : nextCollection != null
                ? 'Start with ${nextCollection!.title}. Recite, check, then tell us how it felt.'
                : 'Your next review will appear here when it is due.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: QuranTheme.subText(context),
              height: 1.5,
            ),
          ),
          if (total > 0) ...[
            const SizedBox(height: 20),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _ProgressStat(
                  value: '${dashboard.masteredCount}',
                  label: 'Mastered',
                ),
                _ProgressStat(
                  value: '$total',
                  label: 'Ayahs in your collections',
                ),
              ],
            ),
          ],
          if (onReview != null) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onReview,
              icon: const AppIcon(Icons.play_arrow_rounded, size: 19),
              label: const Text('Start review'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => PremiumSurface(
    radius: 12,
    borderColor: QuranTheme.outline(context),
    borderWidth: 0.8,
    padding: const EdgeInsets.all(20),
    child: child,
  );
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: QuranTheme.subText(context)),
      ),
    ],
  );
}

class _FirstCollectionCard extends StatelessWidget {
  const _FirstCollectionCard({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppIcon(Icons.collections_bookmark_outlined, size: 30),
        ),
        const SizedBox(height: 14),
        Text(
          'Make it manageable',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Pick a Surah and a short ayah range. Your progress is saved, and reviews are scheduled from your answers.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: QuranTheme.subText(context),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const AppIcon(Icons.add_rounded, size: 18),
          label: const Text('Create your first collection'),
        ),
      ],
    ),
  );
}

class _CollectionCard extends StatefulWidget {
  const _CollectionCard({
    super.key,
    required this.collection,
    required this.dashboard,
    required this.now,
    required this.onReview,
  });
  final HifzCollection collection;
  final HifzDashboard dashboard;
  final DateTime now;
  final VoidCallback onReview;

  @override
  State<_CollectionCard> createState() => _CollectionCardState();
}

class _CollectionCardState extends State<_CollectionCard> {
  bool _deleting = false;
  bool _confirming = false;

  Future<void> _delete() async {
    if (_deleting || _confirming) return;
    _confirming = true;
    final cubit = context.read<HifzDashboardCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete collection?'),
        content: Text(
          'Remove “${widget.collection.title}”? Memorization progress for ayahs used only in this collection will also be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    _confirming = false;
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await cubit.deleteCollection(widget.collection.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete the collection. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final collection = widget.collection;
    final cards = [
      for (final key in collection.verseKeys) ?widget.dashboard.cards[key],
    ];
    final due = cards.where((card) => card.isDue(widget.now)).length;
    final mastered = cards
        .where((card) => card.status == HifzCardStatus.mastered)
        .length;
    DateTime? nextDate;
    for (final card in cards) {
      if (nextDate == null || card.dueAt.isBefore(nextDate)) {
        nextDate = card.dueAt;
      }
    }
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const AppIcon(Icons.collections_bookmark_outlined, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  collection.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Delete collection',
                onPressed: _deleting ? null : _delete,
                icon: const AppIcon(Icons.delete_outline_rounded, size: 19),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${collection.verseKeys.length} ayahs • $mastered mastered',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: QuranTheme.subText(context)),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: collection.verseKeys.isEmpty
                  ? 0
                  : mastered / collection.verseKeys.length,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            due > 0
                ? '$due ${due == 1 ? 'ayah is' : 'ayahs are'} ready for review.'
                : nextDate == null
                ? 'No ayahs in this collection.'
                : 'Nothing due. Next review ${DateFormat.MMMd().format(nextDate)}.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: QuranTheme.subText(context)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: due == 0 || _deleting ? null : widget.onReview,
            icon: const AppIcon(Icons.play_arrow_rounded, size: 18),
            label: Text(due == 0 ? 'All caught up' : 'Review collection'),
          ),
        ],
      ),
    );
  }
}

class _CreateCollectionSheet extends StatefulWidget {
  const _CreateCollectionSheet({required this.cubit});
  final HifzDashboardCubit cubit;

  @override
  State<_CreateCollectionSheet> createState() => _CreateCollectionSheetState();
}

class _CreateCollectionSheetState extends State<_CreateCollectionSheet> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _start = TextEditingController(text: '1');
  final _end = TextEditingController();
  List<QuranSurah> _surahs = const [];
  QuranSurah? _selected;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  @override
  void dispose() {
    _title.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  Future<void> _loadSurahs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final surahs = await getIt<QuranRepository>().getSurahs();
      if (surahs.isEmpty) throw StateError('No Surahs');
      if (!mounted) return;
      setState(() {
        _surahs = surahs;
        _selected = surahs.first;
        _loading = false;
      });
      _title.text = surahs.first.englishName;
      _end.text = '${surahs.first.ayahCount.clamp(1, 7)}';
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load the Surahs. Please try again.';
        });
      }
    }
  }

  void _select(int? number) {
    if (number == null) return;
    final surah = _surahs.firstWhere((item) => item.number == number);
    if (_title.text.trim().isEmpty || _title.text == _selected?.englishName) {
      _title.text = surah.englishName;
    }
    _start.text = '1';
    _end.text = '${surah.ayahCount.clamp(1, 7)}';
    setState(() {
      _selected = surah;
      _error = null;
    });
  }

  String? _validateAyah(String? value) {
    final number = parseLocalizedInt(value);
    return number == null || number < 1 || number > _selected!.ayahCount
        ? 'Enter 1 to ${_selected!.ayahCount}'
        : null;
  }

  Future<void> _save() async {
    if (_saving || _selected == null || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.cubit.createCollection(
        title: _title.text.trim(),
        surahNumber: _selected!.number,
        startAyah: parseLocalizedInt(_start.text)!,
        endAyah: parseLocalizedInt(_end.text)!,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not save this collection. Your choices are still here. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AppSheet(
      title: 'New collection',
      subtitle: 'Choose what you want to memorize.',
      onClose: () {
        if (!_saving) Navigator.of(context).pop();
      },
      child: _loading
          ? const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            )
          : _selected == null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error ?? 'Could not load the Surahs.'),
                TextButton(
                  onPressed: _loadSurahs,
                  child: const Text('Try again'),
                ),
              ],
            )
          : Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _selected!.number,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Surah',
                      helperText: '${_selected!.ayahCount} ayahs',
                    ),
                    items: [
                      for (final surah in _surahs)
                        DropdownMenuItem(
                          value: surah.number,
                          child: Text(
                            '${surah.number}. ${surah.englishName}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _saving ? null : _select,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _title,
                    enabled: !_saving,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Collection name',
                      hintText: 'Give it a familiar name',
                    ),
                    validator: (value) => value?.trim().isNotEmpty == true
                        ? null
                        : 'Enter a collection name',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _start,
                          enabled: !_saving,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'From ayah',
                          ),
                          validator: _validateAyah,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _end,
                          enabled: !_saving,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'To ayah',
                          ),
                          validator: (value) {
                            final error = _validateAyah(value);
                            if (error != null) return error;
                            final start = parseLocalizedInt(_start.text);
                            return start != null &&
                                    parseLocalizedInt(value)! < start
                                ? 'Must be the start or later'
                                : null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Start small. You can create more collections whenever you like.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: QuranTheme.subText(context),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const AppIcon(Icons.add_rounded, size: 18),
                    label: Text(
                      _saving ? 'Saving collection…' : 'Create collection',
                    ),
                  ),
                ],
              ),
            ),
    ),
  );
}
