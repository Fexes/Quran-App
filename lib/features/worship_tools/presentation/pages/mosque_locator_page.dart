import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/storage/settings_store.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/mosque_place.dart';
import '../../domain/repositories/mosque_locator_repository.dart';

class MosqueLocatorPage extends StatefulWidget {
  const MosqueLocatorPage({super.key});

  @override
  State<MosqueLocatorPage> createState() => _MosqueLocatorPageState();
}

class _MosqueLocatorPageState extends State<MosqueLocatorPage> {
  late final SettingsStore _settings;
  late final MosqueLocatorRepository _repository;
  Future<List<MosquePlace>>? _future;
  double _radiusKm = 5;

  @override
  void initState() {
    super.initState();
    _settings = getIt<SettingsStore>();
    _repository = getIt<MosqueLocatorRepository>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).mosquesTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
        children: [
          PremiumSurface(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Search near ${_settings.prayerLocationName}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Uses your saved prayer city, so GPS permission is not required.',
                ),
                const SizedBox(height: 10),
                Text('Radius: ${_radiusKm.round()} km'),
                Slider(
                  value: _radiusKm,
                  min: 1,
                  max: 15,
                  divisions: 14,
                  onChanged: (value) => setState(() => _radiusKm = value),
                ),
                FilledButton.icon(
                  onPressed: () => _search(),
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Search OpenStreetMap'),
                ),
                TextButton(
                  onPressed: () =>
                      context.push(AppRoutes.onboardingPath(edit: true)),
                  child: const Text('Change saved prayer city'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_future == null)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Start a search to see nearby map entries.'),
              ),
            )
          else
            FutureBuilder<List<MosquePlace>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return PremiumSurface(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'The map search is unavailable. You can still open '
                          'OpenStreetMap around your saved city.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _openAreaMap,
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('Open map search'),
                        ),
                      ],
                    ),
                  );
                }
                final places = snapshot.data ?? const [];
                if (places.isEmpty) {
                  return PremiumSurface(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'No tagged mosque entries were found in this radius. '
                          'This does not mean there are no mosques nearby.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _openAreaMap,
                          child: const Text('Search on the map'),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final place in places)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: PremiumSurface(
                          onTap: () => _openPlace(place),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              const Icon(Icons.mosque_outlined),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      place.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(_distanceLabel(place.distanceMeters)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.open_in_new_rounded),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          const SizedBox(height: 14),
          Text(
            'Search is powered by the public Overpass API, limited to 50 '
            'entries and cached locally for 24 hours. Results depend on '
            'community map tags and are not exhaustive.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: QuranTheme.subText(context, 0.62),
            ),
          ),
          TextButton(
            onPressed: () => launchUrl(
              Uri.parse('https://www.openstreetmap.org/copyright'),
              mode: LaunchMode.externalApplication,
            ),
            child: const Text('© OpenStreetMap contributors • ODbL'),
          ),
        ],
      ),
    );
  }

  void _search({bool refresh = false}) {
    setState(() {
      _future = _repository.nearby(
        latitude: _settings.prayerLatitude,
        longitude: _settings.prayerLongitude,
        radiusMeters: (_radiusKm * 1000).round(),
        refresh: refresh,
      );
    });
  }

  Future<void> _openPlace(MosquePlace place) async {
    final uri = Uri.parse(
      'https://www.openstreetmap.org/?mlat=${place.latitude}'
      '&mlon=${place.longitude}#map=18/${place.latitude}/${place.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openAreaMap() async {
    final uri = Uri.parse(
      'https://www.openstreetmap.org/'
      '#map=14/${_settings.prayerLatitude}/${_settings.prayerLongitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _distanceLabel(double meters) {
    return meters < 1000
        ? '${meters.round()} m away'
        : '${(meters / 1000).toStringAsFixed(1)} km away';
  }
}
