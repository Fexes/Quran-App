import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/storage/settings_store.dart';
import 'settings_section_card.dart';

class TranslationVisibilitySettings extends StatefulWidget {
  const TranslationVisibilitySettings({super.key});

  @override
  State<TranslationVisibilitySettings> createState() =>
      _TranslationVisibilitySettingsState();
}

class _TranslationVisibilitySettingsState
    extends State<TranslationVisibilitySettings> {
  late final SettingsStore _store = getIt<SettingsStore>();
  bool _saving = false;

  Future<void> _setVisible(bool value, {required bool quran}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      if (quran) {
        await _store.setQuranTranslationVisible(value);
      } else {
        await _store.setLibraryTranslationEnabled(value);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              context,
              en: 'Could not save this preference. Please try again.',
              ur: 'یہ ترجیح محفوظ نہیں ہو سکی۔ دوبارہ کوشش کریں۔',
              ar: 'تعذر حفظ هذا التفضيل. يرجى المحاولة مرة أخرى.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: _store.translationVisibilityChanges,
    builder: (context, _, _) => Column(
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          secondary: const SettingsItemIcon(Icons.translate_rounded),
          title: Text(
            _text(
              context,
              en: 'Quran translation',
              ur: 'قرآن کا ترجمہ',
              ar: 'ترجمة القرآن',
            ),
          ),
          subtitle: Text(
            _text(
              context,
              en: 'Show translation while reading verses',
              ur: 'آیات پڑھتے وقت ترجمہ دکھائیں',
              ar: 'عرض الترجمة أثناء قراءة الآيات',
            ),
          ),
          value: _store.quranTranslationVisible,
          onChanged: _saving
              ? null
              : (value) => _setVisible(value, quran: true),
        ),
        Divider(
          height: 17,
          thickness: 0.7,
          color: Theme.of(context).colorScheme.outline,
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          secondary: const SettingsItemIcon(Icons.library_books_outlined),
          title: Text(
            _text(
              context,
              en: 'Hadith & Azkar translation',
              ur: 'حدیث اور اذکار کا ترجمہ',
              ar: 'ترجمة الحديث والأذكار',
            ),
          ),
          subtitle: Text(
            _text(
              context,
              en: 'Show translation alongside the Arabic text',
              ur: 'عربی متن کے ساتھ ترجمہ دکھائیں',
              ar: 'عرض الترجمة بجانب النص العربي',
            ),
          ),
          value: _store.libraryTranslationEnabled,
          onChanged: _saving
              ? null
              : (value) => _setVisible(value, quran: false),
        ),
      ],
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
