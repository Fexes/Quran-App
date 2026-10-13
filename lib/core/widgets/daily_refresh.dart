import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:timezone/timezone.dart' as tz;

class DailyRefresh extends StatefulWidget {
  const DailyRefresh({
    super.key,
    required this.onRefresh,
    required this.builder,
    this.timeZone,
  });

  final Future<void> Function() onRefresh;
  final WidgetBuilder builder;
  final String Function()? timeZone;

  @override
  State<DailyRefresh> createState() => _DailyRefreshState();
}

class _DailyRefreshState extends State<DailyRefresh>
    with WidgetsBindingObserver {
  late DateTime _date;
  Timer? _timer;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _date = _now();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      final now = _now();
      if (now.year != _date.year ||
          now.month != _date.month ||
          now.day != _date.day) {
        unawaited(_refresh());
      }
    });
  }

  DateTime _now() {
    try {
      final zone = widget.timeZone?.call();
      if (zone != null) return tz.TZDateTime.now(tz.getLocation(zone));
    } catch (_) {
      // Prayer calculations initialize the zone database on their first load.
    }
    return DateTime.now();
  }

  Future<void> _refresh() async {
    if (!mounted ||
        _refreshing ||
        (WidgetsBinding.instance.lifecycleState != null &&
            WidgetsBinding.instance.lifecycleState !=
                AppLifecycleState.resumed)) {
      return;
    }
    _refreshing = true;
    try {
      await widget.onRefresh();
      _date = _now();
      if (mounted) setState(() {});
    } catch (error) {
      debugPrint('Could not refresh the daily schedule: $error');
    } finally {
      _refreshing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
