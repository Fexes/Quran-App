import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../../../core/theme/quran_theme_cubit.dart';
import '../../../../core/widgets/app_settings_button.dart';
import '../../domain/learning_guide.dart';
import '../widgets/guide_widgets.dart';
import '../widgets/glossary_text.dart';

class GuideReaderPage extends StatefulWidget {
  const GuideReaderPage({
    super.key,
    required this.guide,
    this.initialChapter = 0,
  });

  final LearningGuide guide;

  final int initialChapter;

  @override
  State<GuideReaderPage> createState() => _GuideReaderPageState();
}

class _GuideReaderPageState extends State<GuideReaderPage> {
  late int _index;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _index = widget.initialChapter.clamp(0, widget.guide.chapters.length - 1);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    setState(() => _index = index);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final chapter = widget.guide.chapters[_index];
    final textTheme = Theme.of(context).textTheme;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.guide.title} guide'),
          actions: const [AppSettingsButton()],
        ),
        body: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHAPTER ${_index + 1} OF ${widget.guide.chapters.length}',
                  style: textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.4,
                    color: QuranTheme.subText(context),
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_index + 1) / widget.guide.chapters.length,
                    minHeight: 3,
                    backgroundColor: QuranTheme.surfaceVariant(context),
                    color: QuranTheme.text(context),
                    semanticsLabel: 'Position in guide',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap dotted words for their meaning.',
                  style: textTheme.bodySmall?.copyWith(
                    color: QuranTheme.subText(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 2 / 3,
              child: GuideIllustration(chapter: chapter, showTitle: false),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 25, 4, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlossaryText(
                    chapter.category.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.5,
                      color: QuranTheme.subText(context),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Semantics(
                    header: true,
                    child: GlossaryText(
                      chapter.title,
                      style: textTheme.headlineMedium?.copyWith(height: 1.2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlossaryText(
                    chapter.subtitle,
                    style: textTheme.titleLarge?.copyWith(height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  GlossaryText(
                    chapter.introduction,
                    style: textTheme.bodyLarge?.copyWith(
                      height: 1.65,
                      color: QuranTheme.subText(context, 0.85),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.guide.id == 'umrah' && chapter.id == 'overview')
              const _RitesOverview(),
            if (widget.guide.id == 'umrah' && chapter.id == 'sai')
              const _SaiRoute(),
            if (widget.guide.id == 'umrah' && chapter.id == 'tawaf')
              const _GuideReminder(
                icon: Icons.rotate_left_rounded,
                text:
                    '7 full circuits · Kaaba on your left\n'
                    'Begin and end each circuit at the Black Stone line.',
              ),
            const SizedBox(height: 4),
            for (final (index, step) in chapter.steps.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GuideGuidanceCard(guidance: step, number: index + 1),
              ),
            if (chapter.reminder != null)
              _GuideReminder(text: chapter.reminder!),
            if (chapter.supplications.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 16),
                child: Text(
                  'Words of remembrance',
                  style: textTheme.titleLarge,
                ),
              ),
              for (final supplication in chapter.supplications)
                _SupplicationCard(
                  supplication: supplication,
                  sources: widget.guide.sources,
                ),
            ],
            if (chapter.notes.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 18),
                child: Text('Keep in mind', style: textTheme.titleLarge),
              ),
              for (final note in chapter.notes)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GuideGuidanceCard(guidance: note),
                ),
            ],
            const Divider(height: 28),
            GuideSourcesButton(
              sources: widget.guide.sources,
              sourceIds: chapter.sourceIds,
            ),
            const SizedBox(height: 8),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: QuranTheme.outline(context)),
              ),
            ),
            child: Row(
              children: [
                if (_index > 0) ...[
                  IconButton.outlined(
                    tooltip: 'Previous chapter',
                    onPressed: () => _goTo(_index - 1),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: _index < widget.guide.chapters.length - 1
                        ? () => _goTo(_index + 1)
                        : () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        _index < widget.guide.chapters.length - 1
                            ? 'Next: ${widget.guide.chapters[_index + 1].title}'
                            : 'Back to guide',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideReminder extends StatelessWidget {
  const _GuideReminder({required this.text, this.icon = Icons.info_outline});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: QuranTheme.surfaceVariant(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: GlossaryText(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplicationCard extends StatelessWidget {
  const _SupplicationCard({required this.supplication, required this.sources});

  final GuideSupplication supplication;
  final List<GuideSource> sources;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final arabicFontScale = context.select(
      (QuranThemeCubit cubit) => cubit.state.quranArabicFontScale,
    );
    final source = sources.firstWhere(
      (source) => source.id == supplication.sourceId,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: QuranTheme.surfaceVariant(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: ExpansionTile(
        key: ValueKey(supplication),
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        title: Text(
          supplication.title,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: GlossaryText(
          supplication.context,
          style: textTheme.bodySmall?.copyWith(
            color: QuranTheme.subText(context),
            height: 1.5,
          ),
        ),
        children: [
          SelectableText(
            supplication.arabic,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: textTheme.titleLarge?.copyWith(
              fontSize: 25 * arabicFontScale,
              height: 1.72,
              color: QuranTheme.quranTextNormal(context),
            ),
          ),
          const SizedBox(height: 22),
          SelectableText(
            supplication.transliteration,
            textDirection: TextDirection.ltr,
            style: textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 12),
          GlossaryText(
            supplication.meaning,
            style: textTheme.bodyMedium?.copyWith(
              color: QuranTheme.subText(context, 0.8),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => showGuideSources(
                context,
                sources: sources,
                sourceIds: [supplication.sourceId],
              ),
              child: Text(source.subtitle),
            ),
          ),
        ],
      ),
    );
  }
}

class _RitesOverview extends StatelessWidget {
  const _RitesOverview();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: QuranTheme.surfaceVariant(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The four rites',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          for (final (index, entry) in const [
            ('Ihram', 'Enter the state of worship at the miqat.'),
            ('Tawaf', 'Circle the Kaaba seven times.'),
            ('Sa’i', 'Walk seven lengths between Safa and Marwah.'),
            ('Haircut', 'Shave or shorten the hair to finish.'),
          ].indexed)
            Padding(
              padding: EdgeInsets.only(bottom: index == 3 ? 0 : 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '0${index + 1}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlossaryText(
                          entry.$1,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            height: 1.6,
                          ),
                        ),
                        GlossaryText(
                          entry.$2,
                          style: const TextStyle(height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SaiRoute extends StatelessWidget {
  const _SaiRoute();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: QuranTheme.surfaceVariant(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Count each one-way length',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          for (var length = 1; length <= 7; length++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text('$length'),
                  ),
                  Expanded(
                    child: GlossaryText(length.isOdd ? 'Safa' : 'Marwah'),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.arrow_forward_rounded, size: 18),
                  ),
                  Expanded(
                    child: GlossaryText(length.isOdd ? 'Marwah' : 'Safa'),
                  ),
                ],
              ),
            ),
          const Divider(height: 18),
          GlossaryText(
            'Start at Safa. Finish at Marwah.',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}
