import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../domain/learning_guide.dart';

class GuideSourcesButton extends StatelessWidget {
  const GuideSourcesButton({super.key, required this.sources, this.sourceIds});

  final List<GuideSource> sources;
  final List<String>? sourceIds;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () =>
          showGuideSources(context, sources: sources, sourceIds: sourceIds),
      icon: const Icon(Icons.library_books_outlined, size: 18),
      label: const Text('Sources & references'),
    );
  }
}

Future<void> showGuideSources(
  BuildContext context, {
  required List<GuideSource> sources,
  List<String>? sourceIds,
}) async {
  final references = sources
      .where((source) => sourceIds == null || sourceIds.contains(source.id))
      .toList();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Directionality(
      textDirection: TextDirection.ltr,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Sources & references',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Qur’an, hadith and scholarly guidance. '
                      'Reference links open online.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: QuranTheme.subText(context),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              for (final (index, source) in references.indexed) ...[
                if (index > 0) const Divider(height: 1, indent: 22),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 4,
                  ),
                  title: Text(source.title),
                  subtitle: Text(source.subtitle),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () => _openSource(context, source.url),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _openSource(BuildContext context, String url) async {
  try {
    if (await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      return;
    }
  } catch (_) {
    // Keep the offline guide available if a browser cannot be opened.
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Could not open the reference. Try again online.'),
    ),
  );
}
