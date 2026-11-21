import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/header_pattern_backdrop.dart';
import 'home_widget_content.dart';
import 'home_widget_host.dart';
import 'home_widget_snapshot_service.dart';
import 'home_widget_preview.dart';

class HomeWidgetGalleryPage extends StatefulWidget {
  const HomeWidgetGalleryPage({super.key});

  @override
  State<HomeWidgetGalleryPage> createState() => _HomeWidgetGalleryPageState();
}

class _HomeWidgetGalleryPageState extends State<HomeWidgetGalleryPage> {
  final _service = HomeWidgetSnapshotService();
  late Future<HomeWidgetSnapshot> _snapshot;
  final _sizes = <HomeWidgetKind, HomeWidgetSize>{};
  bool _pinSupported = false;
  bool _pinning = false;

  bool get _android => defaultTargetPlatform == TargetPlatform.android;
  bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

  String _text(String en, String ar, String ur) =>
      widgetText(Localizations.localeOf(context).languageCode, en, ar, ur);

  @override
  void initState() {
    super.initState();
    _reload();
    if (_android) _checkPinning();
  }

  void _reload() => _snapshot = _service.load();

  Future<void> _checkPinning() async {
    try {
      final supported = await HomeWidgetPlatform.canPin();
      if (mounted) setState(() => _pinSupported = supported);
    } on PlatformException {
      // The launcher's widget picker is still available.
    } on MissingPluginException {
      // Preview-only Flutter hosts have no Android launcher.
    }
  }

  Future<void> _add(HomeWidgetKind kind, HomeWidgetSize size) async {
    if (_pinning) return;
    if (_pinSupported) {
      setState(() => _pinning = true);
      try {
        await HomeWidgetPlatform.publish(await _service.load());
        if (await HomeWidgetPlatform.pin(kind, size)) return;
      } catch (error) {
        debugPrint('Widget pinning failed: $error');
      } finally {
        if (mounted) setState(() => _pinning = false);
      }
    }
    if (!mounted) return;
    final title =
        _android &&
            kind == HomeWidgetKind.prayer &&
            size == HomeWidgetSize.medium
        ? _text(
            'Next Prayer (Medium)',
            'الصلاة التالية (متوسط)',
            'اگلی نماز (درمیانہ)',
          )
        : kind.label(Localizations.localeOf(context).languageCode);
    final instructions = _ios
        ? _text(
            'Touch and hold an empty area on your Home Screen. Tap Edit, then Add Widget. Search for Quran, choose $title and the size you want, then tap Add Widget.',
            'اضغط مطولاً على مساحة فارغة في الشاشة الرئيسية. اضغط تحرير ثم إضافة أداة. ابحث عن Quran واختر $title والحجم ثم أضف الأداة.',
            'ہوم اسکرین پر خالی جگہ کو دبائے رکھیں۔ ترمیم، پھر ویجٹ شامل کریں پر ٹیپ کریں۔ Quran تلاش کریں، $title اور سائز منتخب کریں، پھر ویجٹ شامل کریں۔',
          )
        : _text(
            'Touch and hold an empty area on your Home Screen. Tap Widgets, find Quran, then touch and drag $title onto your Home Screen.',
            'اضغط مطولاً على مساحة فارغة في الشاشة الرئيسية. اختر الأدوات ثم Quran واسحب $title إلى الشاشة الرئيسية.',
            'ہوم اسکرین پر خالی جگہ کو دبائے رکھیں۔ ویجٹس پر ٹیپ کریں، Quran تلاش کریں اور $title کو ہوم اسکرین پر گھسیٹیں۔',
          );
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(instructions),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _text(
            'Home Screen Widgets',
            'أدوات الشاشة الرئيسية',
            'ہوم اسکرین ویجٹس',
          ),
        ),
        flexibleSpace: const HeaderPatternBackdrop(),
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder(
          future: _snapshot,
          builder: (context, state) {
            if (state.hasError) {
              return Center(
                child: TextButton.icon(
                  onPressed: () => setState(_reload),
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    _text(
                      'Reload widget previews',
                      'أعد تحميل المعاينات',
                      'پیش منظر دوبارہ لوڈ کریں',
                    ),
                  ),
                ),
              );
            }
            final snapshot = state.data;
            if (snapshot == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              itemCount: HomeWidgetKind.values.length,
              separatorBuilder: (_, _) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                final kind = HomeWidgetKind.values[index];
                final size = _sizes[kind] ?? kind.sizes.first;
                final content = snapshot.contentAt(kind, DateTime.now());
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(kind.icon, size: 21),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                kind.label(language),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        if (kind.sizes.length > 1) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final option in kind.sizes)
                                ChoiceChip(
                                  label: Text(
                                    option == HomeWidgetSize.small
                                        ? _text('Small', 'صغير', 'چھوٹا')
                                        : _text('Medium', 'متوسط', 'درمیانہ'),
                                  ),
                                  selected: size == option,
                                  onSelected: (_) =>
                                      setState(() => _sizes[kind] = option),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: HomeWidgetPreview(
                            kind: kind,
                            content: content,
                            size: size,
                            dark: snapshot.dark,
                          ),
                        ),
                        if (_ios || _android)
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TextButton.icon(
                              onPressed: _pinning
                                  ? null
                                  : () => _add(kind, size),
                              icon: Icon(
                                _pinSupported ? Icons.add : Icons.info_outline,
                              ),
                              label: Text(
                                _pinSupported
                                    ? _text(
                                        'Add to Home Screen',
                                        'أضف إلى الشاشة الرئيسية',
                                        'ہوم اسکرین میں شامل کریں',
                                      )
                                    : _text(
                                        'How to Add',
                                        'طريقة الإضافة',
                                        'شامل کرنے کا طریقہ',
                                      ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
