import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/content/content_source.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../azkar/domain/entities/azkar_category.dart';
import '../../../azkar/domain/entities/dhikr_item.dart';
import '../../../azkar/domain/repositories/azkar_repository.dart';
import '../../../library/data/stores/library_user_data_store.dart';

class DuasPage extends StatefulWidget {
  const DuasPage({super.key});

  @override
  State<DuasPage> createState() => _DuasPageState();
}

class _DuasPageState extends State<DuasPage> {
  late final AzkarRepository _repository;
  late final LibraryUserDataStore _userData;
  late Future<_DuaData> _future;
  String _query = '';
  String? _category;
  bool _favoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _repository = getIt<AzkarRepository>();
    _userData = getIt<LibraryUserDataStore>();
    _future = _load();
  }

  Future<_DuaData> _load() async {
    final results = await Future.wait<Object>([
      _repository.getCategories(),
      _repository.getDhikr(limit: 1000),
      _repository.getContentSources(),
    ]);
    return _DuaData(
      categories: results[0] as List<AzkarCategory>,
      items: results[1] as List<DhikrItem>,
      sources: results[2] as List<ContentSource>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).duasTitle)),
      body: FutureBuilder<_DuaData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: FilledButton.icon(
                onPressed: () => setState(() => _future = _load()),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry loading Duas'),
              ),
            );
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final normalized = _query.trim().toLowerCase();
          final visible = data.items
              .where((item) {
                if (_category != null && item.categoryId != _category) {
                  return false;
                }
                if (_favoritesOnly &&
                    !_userData.isBookmarked('dua:${item.id}')) {
                  return false;
                }
                if (normalized.isEmpty) {
                  return true;
                }
                return '${item.title} ${item.arabic} ${item.translation} '
                        '${item.transliteration} ${item.reference}'
                    .toLowerCase()
                    .contains(normalized);
              })
              .toList(growable: false);
          final featured =
              data.items[DateTime.now()
                      .difference(DateTime(2020))
                      .inDays
                      .abs() %
                  data.items.length];
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
            children: [
              _FeaturedDua(item: featured),
              const SizedBox(height: 14),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Search title, Arabic, meaning, or reference',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      selected: _category == null && !_favoritesOnly,
                      label: const Text('All'),
                      onSelected: (_) => setState(() {
                        _category = null;
                        _favoritesOnly = false;
                      }),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      selected: _favoritesOnly,
                      label: const Text('Favorites'),
                      onSelected: (_) => setState(() {
                        _category = null;
                        _favoritesOnly = true;
                      }),
                    ),
                    for (final category in data.categories) ...[
                      const SizedBox(width: 8),
                      ChoiceChip(
                        selected: _category == category.id,
                        label: Text(category.englishName),
                        onSelected: (_) => setState(() {
                          _category = category.id;
                          _favoritesOnly = false;
                        }),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: Text('No matching Duas.')),
                )
              else
                for (final item in visible)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DuaCard(
                      item: item,
                      favorite: _userData.isBookmarked('dua:${item.id}'),
                      onFavorite: () async {
                        await _userData.toggleBookmark('dua:${item.id}');
                        if (mounted) {
                          setState(() {});
                        }
                      },
                    ),
                  ),
              const SizedBox(height: 8),
              Text(
                data.sources.isEmpty
                    ? 'Each entry displays its supplied reference.'
                    : 'Source: ${data.sources.first.name}. '
                          '${data.sources.first.attribution}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: QuranTheme.subText(context, 0.62),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DuaData {
  const _DuaData({
    required this.categories,
    required this.items,
    required this.sources,
  });

  final List<AzkarCategory> categories;
  final List<DhikrItem> items;
  final List<ContentSource> sources;
}

class _FeaturedDua extends StatelessWidget {
  const _FeaturedDua({required this.item});

  final DhikrItem item;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(18),
      prominent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'DUA OF THE DAY',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.arabic,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              height: 1.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(item.translation),
          const SizedBox(height: 8),
          Text(
            item.reference,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DuaCard extends StatelessWidget {
  const _DuaCard({
    required this.item,
    required this.favorite,
    required this.onFavorite,
  });

  final DhikrItem item;
  final bool favorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title.isEmpty ? 'Supplication' : item.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                tooltip: favorite ? 'Remove favorite' : 'Add favorite',
                onPressed: onFavorite,
                icon: Icon(
                  favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                ),
              ),
            ],
          ),
          Text(
            item.arabic,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(height: 1.8),
          ),
          const SizedBox(height: 8),
          Text(item.translation),
          if (item.transliteration.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.transliteration,
              style: TextStyle(color: QuranTheme.subText(context, 0.68)),
            ),
          ],
          const SizedBox(height: 9),
          Text(
            '${item.reference} • Source ${item.sourceId}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
