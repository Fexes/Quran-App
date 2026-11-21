import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/di/injection.dart';
import '../../app/router/app_router.dart';
import '../../app/router/app_routes.dart';
import '../../core/search/local_search_revision.dart';
import '../../core/storage/settings_store.dart';
import '../shell/presentation/bloc/shell_cubit.dart';
import '../shell/presentation/bloc/shell_state.dart';
import 'home_widget_content.dart';
import 'home_widget_snapshot_service.dart';

class HomeWidgetPlatform {
  static const channel = MethodChannel('quran/home_screen_widgets');

  static Future<void> publish(HomeWidgetSnapshot snapshot) =>
      channel.invokeMethod<void>('publish', jsonEncode(snapshot.toJson()));

  static Future<bool> canPin() async =>
      await channel.invokeMethod<bool>('canPin') ?? false;

  static Future<bool> pin(HomeWidgetKind kind, HomeWidgetSize size) async =>
      await channel.invokeMethod<bool>('pin', {
        'kind': kind.id,
        'size': size.name,
      }) ??
      false;
}

class HomeWidgetHost extends StatefulWidget {
  const HomeWidgetHost({super.key, required this.child});

  final Widget child;

  @override
  State<HomeWidgetHost> createState() => _HomeWidgetHostState();
}

class _HomeWidgetHostState extends State<HomeWidgetHost>
    with WidgetsBindingObserver {
  static const _sources = [
    'quran-user',
    'quran-translations',
    'reading',
    'hifz',
  ];

  final _service = HomeWidgetSnapshotService();
  final _supportsWidgets = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  SettingsStore? _settings;
  Timer? _debounce;
  Future<void>? _inFlight;
  String? _revision;
  String? _pendingPath;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    if (!_supportsWidgets) return;
    _settings = getIt<SettingsStore>();
    _revision = _currentRevision;
    WidgetsBinding.instance.addObserver(this);
    _settings!.beforePersonalDataErase.add(_clear);
    LocalSearchRevision.changes.addListener(_onDataChanged);
    HomeWidgetPlatform.channel.setMethodCallHandler((call) async {
      if (call.method == 'linkAvailable') await _takeLink();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_takeLink());
      _queueSync();
    });
  }

  String get _currentRevision {
    final settings = _settings!;
    return [
      ..._sources.map(LocalSearchRevision.forSource),
      settings.shouldShowOnboarding,
      settings.prayerLocationName,
      settings.prayerLatitude,
      settings.prayerLongitude,
      settings.prayerTimeZone,
      settings.prayerMethod,
      settings.prayerAsrMadhab,
      settings.themePresetId,
      settings.localeCode,
    ].join('|');
  }

  void _onDataChanged() {
    final revision = _currentRevision;
    if (revision == _revision) return;
    _revision = revision;
    _queueSync();
    if (_pendingPath != null && _settings?.shouldShowOnboarding == false) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openPendingPath());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_takeLink());
      _queueSync();
    }
  }

  @override
  void didChangeLocales(List<Locale>? locales) => _queueSync();

  void _queueSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () async {
      if (!mounted || _clearing || _settings!.shouldShowOnboarding) return;
      if (_inFlight != null) {
        _queueSync();
        return;
      }
      final sync = _publish();
      _inFlight = sync;
      await sync;
      if (identical(_inFlight, sync)) _inFlight = null;
    });
  }

  Future<void> _publish() async {
    try {
      final snapshot = await _service.load();
      if (mounted && !_clearing) await HomeWidgetPlatform.publish(snapshot);
    } catch (error) {
      debugPrint('Home widget refresh failed: $error');
    }
  }

  Future<void> _clear() async {
    _clearing = true;
    _debounce?.cancel();
    try {
      await _inFlight;
      await HomeWidgetPlatform.channel.invokeMethod<void>('clear');
    } on PlatformException catch (error) {
      debugPrint('Home widget clear failed: $error');
    } on MissingPluginException {
      // No widget data exists on hosts without a native bridge.
    } finally {
      _clearing = false;
    }
  }

  Future<void> _takeLink() async {
    try {
      final path = await HomeWidgetPlatform.channel.invokeMethod<String>(
        'takeLink',
      );
      if (!mounted || path == null) return;
      _pendingPath = path;
      _openPendingPath();
    } on MissingPluginException {
      // Other Flutter hosts do not provide a widget bridge.
    } on PlatformException catch (error) {
      debugPrint('Home widget link failed: $error');
    }
  }

  void _openPendingPath() {
    final path = _pendingPath;
    if (!mounted || path == null || _settings?.shouldShowOnboarding != false) {
      return;
    }
    if (appRouter.routeInformationProvider.value.uri.path ==
        AppRoutes.onboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openPendingPath());
      return;
    }
    _pendingPath = null;
    if (path == HomeWidgetSnapshotService.prayerPath) {
      context.read<ShellCubit>().setDestination(ShellDestination.prayer);
      appRouter.go(AppRoutes.shell);
    } else if (path == AppRoutes.shell) {
      context.read<ShellCubit>().setDestination(ShellDestination.home);
      appRouter.go(AppRoutes.shell);
    } else {
      final uri = Uri.tryParse(path);
      if (uri != null &&
          !uri.hasAuthority &&
          !uri.hasScheme &&
          _isWidgetRoute(uri.path)) {
        unawaited(appRouter.push<void>(path));
      }
    }
  }

  bool _isWidgetRoute(String path) =>
      path == AppRoutes.hifz ||
      path == AppRoutes.readingGoals ||
      path == AppRoutes.ramadan ||
      path == AppRoutes.fastingJournal ||
      RegExp(r'^/quran/[1-9][0-9]{0,2}$').hasMatch(path) ||
      RegExp(r'^/hifz/review/[^/]+$').hasMatch(path) ||
      path == AppRoutes.azkarCategoryPath('morning-and-evening');

  @override
  void dispose() {
    if (_supportsWidgets) {
      WidgetsBinding.instance.removeObserver(this);
      LocalSearchRevision.changes.removeListener(_onDataChanged);
      _settings?.beforePersonalDataErase.remove(_clear);
      HomeWidgetPlatform.channel.setMethodCallHandler(null);
      _debounce?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
