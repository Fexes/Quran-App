import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/app/di/injection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran/features/search/domain/repositories/offline_search_repository.dart';
import 'package:quran/features/search/domain/entities/offline_search_result.dart';

/// Run on an explicitly selected physical device with flutter run --profile -t.
/// Uses the packaged assets and persistent worker, exactly as the app does.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: _BenchmarkPage()));
}

class _BenchmarkPage extends StatefulWidget {
  const _BenchmarkPage();
  @override
  State<_BenchmarkPage> createState() => _BenchmarkPageState();
}

class _BenchmarkPageState extends State<_BenchmarkPage> {
  String _status = 'Checking offline search...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    OfflineSearchRepository? repository;
    final initialization = Stopwatch()..start();
    final report = <String, dynamic>{
      'platform': Platform.operatingSystem,
      'operating_system': Platform.operatingSystemVersion,
      'physical_device_requested': true,
      'model': 'intfloat/multilingual-e5-small INT8',
      'scope':
          'Full packaged corpus plus current app source registry and live providers',
      'queries': <Map<String, dynamic>>[],
      'quality_judgments':
          'Not supplied; these are performance and execution checks.',
      'rss_before_bytes': ProcessInfo.currentRss,
    };
    try {
      report['corpus'] =
          (jsonDecode(
                await rootBundle.loadString(
                  'assets/offline_search/manifest.json',
                ),
              )
              as Map)['corpus'];
      await configureDependencies(initializePrayerAlerts: false);
      repository = getIt<OfflineSearchRepository>();
      await repository.warmUp();
      report['initialization_ms'] = initialization.elapsedMilliseconds;
      report['rss_after_initialization_bytes'] = ProcessInfo.currentRss;
      for (final query in [
        "I'm worried about my future.",
        'مجھے اپنے مستقبل کی فکر ہے',
        'أشعر بالقلق بشأن مستقبلي',
        'Mujhe apne mustaqbil ki fikar hai',
        'What helps when life is difficult?',
        'How should I treat my parents?',
        '2 : 255',
        'bukhari 1',
        'bukhari 999999',
        'When is the next prayer?',
        'Where can I find my downloaded languages?',
        'How can I track my fasting?',
      ]) {
        final runs = <Map<String, dynamic>>[];
        for (var i = 0; i < 5; i++) {
          final clock = Stopwatch()..start();
          final result = await repository.search(query);
          runs.add({
            'round_trip_ms': clock.elapsedMilliseconds,
            'timings_ms': result.timingsMs,
            'semantic_available': result.semanticAvailable,
            'warning': result.warning,
            'pending_documents': result.pendingDocuments,
            'top_10': [
              for (final hit in result.hits.take(10)) hit.passage.canonicalId,
            ],
          });
          if (!result.semanticAvailable) {
            throw StateError(result.warning ?? 'Native embedding unavailable.');
          }
          if (query == '2 : 255' &&
              !result.hits.any(
                (hit) => hit.passage.canonicalId == 'quran:2:255',
              )) {
            throw StateError('Exact verse navigation failed.');
          }
          if (query == 'bukhari 999999' && result.hits.isNotEmpty) {
            throw StateError(
              'Missing exact reference incorrectly used similarity.',
            );
          }
        }
        (report['queries'] as List).add({'query': query, 'runs': runs});
      }
      for (final filter in [
        OfflineSearchFilter.quran,
        OfflineSearchFilter.hadith,
      ]) {
        final result = await repository.search('patience', filter: filter);
        if (result.hits.any((hit) => hit.passage.kind != filter.name)) {
          throw StateError('Source filtering failed.');
        }
      }
      report['status'] = 'passed';
      if (mounted) setState(() => _status = 'Offline search checks passed.');
    } catch (error, stack) {
      report['status'] = 'failed';
      report['error'] = error.toString();
      report['stack'] = stack.toString();
      if (mounted) setState(() => _status = 'Offline search checks failed.');
    } finally {
      report['rss_peak_bytes'] = ProcessInfo.maxRss;
      await repository?.dispose();
      final directory = await getApplicationSupportDirectory();
      await File('${directory.path}/app_search_benchmark.json').writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(report)}\n',
        flush: true,
      );
      // Emitted once for capture by the development runner, never shown as UI.
      developer.log(
        'OFFLINE_SEARCH_BENCHMARK ${jsonEncode(report)}',
        name: 'offline_search',
      );
      // ignore: avoid_print
      print('OFFLINE_SEARCH_BENCHMARK ${jsonEncode(report)}');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: Text(_status, textAlign: TextAlign.center)),
  );
}
