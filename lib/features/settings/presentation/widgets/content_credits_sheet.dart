import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/content/content_source.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../azkar/domain/repositories/azkar_repository.dart';
import '../../../hadith/domain/repositories/hadith_repository.dart';
import '../../../quran/domain/repositories/quran_repository.dart';

class ContentCreditsSheet extends StatelessWidget {
  const ContentCreditsSheet({super.key});

  static String titleFor(BuildContext context) => _text(
    context,
    en: 'Sources & credits',
    ur: 'ماخذ اور کریڈٹس',
    ar: 'المصادر والشكر',
  );

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const ContentCreditsSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppSheet(
      title: titleFor(context),
      subtitle: _text(
        context,
        en: 'Content providers, attribution and licenses.',
        ur: 'مواد فراہم کرنے والے، انتساب اور لائسنس۔',
        ar: 'مزودو المحتوى ونسبته إلى مصادره والتراخيص.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ContentSourceGroup(
            title: l10n.quranTitle,
            loadSources: () => getIt<QuranRepository>().getContentSources(),
          ),
          _ContentSourceGroup(
            title: l10n.hadithTitle,
            loadSources: () => getIt<HadithRepository>().getContentSources(),
          ),
          _ContentSourceGroup(
            title: l10n.azkarTitle,
            loadSources: () => getIt<AzkarRepository>().getContentSources(),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => showLicensePage(context: context),
            icon: const AppIcon(Icons.verified_outlined, size: 18),
            label: Text(
              _text(
                context,
                en: 'Open-source licenses',
                ur: 'اوپن سورس لائسنس',
                ar: 'تراخيص البرامج مفتوحة المصدر',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentSourceGroup extends StatefulWidget {
  const _ContentSourceGroup({required this.title, required this.loadSources});

  final String title;
  final Future<List<ContentSource>> Function() loadSources;

  @override
  State<_ContentSourceGroup> createState() => _ContentSourceGroupState();
}

class _ContentSourceGroupState extends State<_ContentSourceGroup> {
  late final Future<List<ContentSource>> _sources;

  @override
  void initState() {
    super.initState();
    _sources = Future.sync(widget.loadSources);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        FutureBuilder<List<ContentSource>>(
          future: _sources,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                _text(
                  context,
                  en: 'These sources could not be loaded.',
                  ur: 'یہ ماخذ لوڈ نہیں ہو سکے۔',
                  ar: 'تعذر تحميل هذه المصادر.',
                ),
              );
            }
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            final sources = snapshot.data ?? const <ContentSource>[];
            if (sources.isEmpty) {
              return Text(
                _text(
                  context,
                  en: 'No sources available.',
                  ur: 'کوئی ماخذ دستیاب نہیں۔',
                  ar: 'لا توجد مصادر متاحة.',
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final source in sources)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ContentSourceCredit(source: source),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class _ContentSourceCredit extends StatelessWidget {
  const _ContentSourceCredit({required this.source});

  final ContentSource source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = <String>{
      if (source.provider?.trim().isNotEmpty == true) source.provider!.trim(),
      if (source.edition?.trim().isNotEmpty == true) source.edition!.trim(),
      if (source.attribution.trim().isNotEmpty) source.attribution.trim(),
    }..remove(source.name.trim());
    final sourceUrl = _webUri(source.url);
    final licenseUrl = _webUri(source.licenseUrl);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(source.name, style: theme.textTheme.titleSmall),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(details.join('\n'), style: theme.textTheme.bodySmall),
          ],
          if (source.license?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              '${_text(context, en: 'License', ur: 'لائسنس', ar: 'الترخيص')}: ${source.license!.trim()}',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (sourceUrl != null || licenseUrl != null) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [
                if (sourceUrl != null)
                  TextButton.icon(
                    onPressed: () => _openLink(context, sourceUrl),
                    icon: const AppIcon(Icons.open_in_new_rounded, size: 16),
                    label: Text(
                      _text(
                        context,
                        en: 'Source website',
                        ur: 'ماخذ کی ویب سائٹ',
                        ar: 'موقع المصدر',
                      ),
                    ),
                  ),
                if (licenseUrl != null)
                  TextButton.icon(
                    onPressed: () => _openLink(context, licenseUrl),
                    icon: const AppIcon(Icons.open_in_new_rounded, size: 16),
                    label: Text(
                      _text(
                        context,
                        en: 'License details',
                        ur: 'لائسنس کی تفصیلات',
                        ar: 'تفاصيل الترخيص',
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

Uri? _webUri(String? value) {
  final uri = Uri.tryParse(value?.trim() ?? '');
  if (uri == null ||
      !{'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
      uri.host.isEmpty) {
    return null;
  }
  return uri;
}

Future<void> _openLink(BuildContext context, Uri uri) async {
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  } catch (_) {
    // The failure is reported below if this sheet is still open.
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        _text(
          context,
          en: 'This link could not be opened.',
          ur: 'یہ لنک نہیں کھل سکا۔',
          ar: 'تعذر فتح هذا الرابط.',
        ),
      ),
    ),
  );
}

String _text(
  BuildContext context, {
  required String en,
  required String ur,
  required String ar,
}) => switch (Localizations.localeOf(context).languageCode) {
  'ur' => ur,
  'ar' => ar,
  _ => en,
};
