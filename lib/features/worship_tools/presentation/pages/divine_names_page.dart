import 'package:flutter/material.dart';
import '../../../../core/widgets/app_icon.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/architectural_backdrop.dart';
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
  late Future<List<DivineName>> _names;
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
        flexibleSpace: const ArchitecturalBackdrop(),
      ),
      body: FutureBuilder<List<DivineName>>(
        future: _names,
        builder: (context, snapshot) {
          if (snapshot.hasError || snapshot.data?.isEmpty == true) {
            return AppErrorView(
              title: 'Names unavailable',
              message: 'The local collection could not be loaded.',
              onRetry: () => setState(() {
                _names = getIt<DivineNamesRepository>().all();
              }),
            );
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
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                sliver: SliverList.list(
                  children: [
                    _FeaturedName(name: featured),
                    const SizedBox(height: 14),
                    TextField(
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        hintText: 'Search Arabic, transliteration, or meaning',
                        prefixIcon: AppIcon(Icons.search_rounded),
                      ),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text('$learnedCount of 99 marked learned'),
                      subtitle: const Text('Show learned Names only'),
                      value: _learnedOnly,
                      onChanged: (value) =>
                          setState(() => _learnedOnly = value),
                    ),
                    if (visible.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No matching Names.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final name = visible[index];
                    final learned = _userData.isBookmarked(_key(name));
                    return ListTile(
                      key: ValueKey(name.number),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      onTap: () async {
                        await _userData.toggleBookmark(_key(name));
                        if (mounted) {
                          setState(() {});
                        }
                      },
                      leading: Text(
                        '${name.number}',
                        style: TextStyle(
                          color: QuranTheme.subText(context, 0.58),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Tooltip(
                        message: learned
                            ? 'Mark as not learned'
                            : 'Mark as learned',
                        child: AppIcon(
                          learned
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: learned
                              ? Theme.of(context).colorScheme.primary
                              : QuranTheme.subText(context, 0.35),
                        ),
                      ),
                      title: Text(
                        name.arabic,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            name.transliteration,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            name.meaning,
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
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                sliver: SliverToBoxAdapter(
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Source and attribution'),
                    children: [
                      Text(
                        'Arabic, transliteration, and English meanings: '
                        'my-prayers/muslim-data, Apache-2.0. The source edition does '
                        'not include per-name verse references or licensed audio. '
                        'Meaning wording requires final scholarly review.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: QuranTheme.subText(context, 0.62),
                        ),
                      ),
                    ],
                  ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(
            'Name of the day • ${name.number} of 99',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name.arabic,
            textDirection: TextDirection.rtl,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            name.transliteration,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(name.meaning, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
