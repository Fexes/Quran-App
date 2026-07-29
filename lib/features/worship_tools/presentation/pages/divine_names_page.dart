import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../library/data/stores/library_user_data_store.dart';
import '../../domain/entities/divine_name.dart';
import '../../domain/repositories/divine_names_repository.dart';

class DivineNamesPage extends StatefulWidget {
  const DivineNamesPage({super.key});

  @override
  State<DivineNamesPage> createState() => _DivineNamesPageState();
}

class _DivineNamesPageState extends State<DivineNamesPage> {
  late final LibraryUserDataStore _userData;
  late final Future<List<DivineName>> _names;
  String _query = '';
  bool _learnedOnly = false;

  @override
  void initState() {
    super.initState();
    _userData = getIt<LibraryUserDataStore>();
    _names = getIt<DivineNamesRepository>().all();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).divineNamesTitle),
      ),
      body: FutureBuilder<List<DivineName>>(
        future: _names,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final names = snapshot.data;
          if (names == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final learnedCount = names
              .where((item) => _userData.isBookmarked(_key(item)))
              .length;
          final normalized = _query.trim().toLowerCase();
          final visible = names
              .where((item) {
                if (_learnedOnly && !_userData.isBookmarked(_key(item))) {
                  return false;
                }
                return normalized.isEmpty ||
                    '${item.arabic} ${item.transliteration} ${item.meaning}'
                        .toLowerCase()
                        .contains(normalized);
              })
              .toList(growable: false);
          final featured =
              names[DateTime.now().difference(DateTime(2020)).inDays.abs() %
                  names.length];
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
            children: [
              _FeaturedName(name: featured),
              const SizedBox(height: 14),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Search Arabic, transliteration, or meaning',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('$learnedCount of 99 marked learned'),
                subtitle: const Text('Show learned Names only'),
                value: _learnedOnly,
                onChanged: (value) => setState(() => _learnedOnly = value),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visible.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.92,
                ),
                itemBuilder: (context, index) {
                  final name = visible[index];
                  final learned = _userData.isBookmarked(_key(name));
                  return PremiumSurface(
                    onTap: () async {
                      await _userData.toggleBookmark(_key(name));
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    padding: const EdgeInsets.all(13),
                    prominent: learned,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${name.number}',
                              style: TextStyle(
                                color: QuranTheme.subText(context, 0.58),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Icon(
                              learned
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              size: 19,
                              color: learned
                                  ? Theme.of(context).colorScheme.primary
                                  : QuranTheme.subText(context, 0.35),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          name.arabic,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          name.transliteration,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          name.meaning,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (name.references.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            name.references.join(', '),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Arabic, transliteration, and English meanings: '
                'my-prayers/muslim-data, Apache-2.0. The source edition does '
                'not include per-name verse references or licensed audio. '
                'Meaning wording requires final scholarly review.',
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

  String _key(DivineName name) => 'divine-name:${name.number}';
}

class _FeaturedName extends StatelessWidget {
  const _FeaturedName({required this.name});

  final DivineName name;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(22),
      prominent: true,
      child: Column(
        children: [
          Text(
            'NAME OF THE DAY • ${name.number} OF 99',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name.arabic,
            textDirection: TextDirection.rtl,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            name.transliteration,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(name.meaning, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
