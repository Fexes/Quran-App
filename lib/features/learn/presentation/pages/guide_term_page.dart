import 'package:flutter/material.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_page_app_bar.dart';
import '../../domain/guide_term.dart';
import '../widgets/guide_sources.dart';

class GuideTermPage extends StatelessWidget {
  const GuideTermPage({super.key, required this.term});

  final GuideTerm term;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppPageAppBar(title: Text(term.title)),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
            children: [
              Text(
                term.definition,
                style: textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
              for (final detail in term.details) ...[
                const SizedBox(height: 26),
                Semantics(
                  header: true,
                  child: Text(detail.title, style: textTheme.titleLarge),
                ),
                const SizedBox(height: 10),
                Text(
                  detail.body,
                  style: textTheme.bodyMedium?.copyWith(
                    color: QuranTheme.subText(context, 0.85),
                    height: 1.65,
                  ),
                ),
              ],
              if (term.sources.isNotEmpty) ...[
                const SizedBox(height: 26),
                const Divider(),
                GuideSourcesButton(sources: term.sources),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
