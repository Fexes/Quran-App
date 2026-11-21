import '../../../../core/widgets/app_page_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/header_pattern_backdrop.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../data/services/nearby_mosques_launcher.dart';

class MosqueLocatorPage extends StatefulWidget {
  const MosqueLocatorPage({super.key});

  @override
  State<MosqueLocatorPage> createState() => _MosqueLocatorPageState();
}

class _MosqueLocatorPageState extends State<MosqueLocatorPage> {
  bool _opening = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openMaps();
    });
  }

  Future<void> _openMaps() async {
    if (_opening) return;
    _opening = true;
    if (_failed) setState(() => _failed = false);
    final opened = await NearbyMosquesLauncher.open();
    if (!mounted) return;
    _opening = false;
    if (opened) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.shell);
      }
    } else {
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppPageAppBar(
      title: Text(AppLocalizations.of(context).mosquesTitle),
      flexibleSpace: const HeaderPatternBackdrop(),
    ),
    body: _failed
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Maps could not be opened.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(onPressed: _openMaps, child: const Text('Retry')),
                ],
              ),
            ),
          )
        : const AppLoadingView(label: 'Opening maps…'),
  );
}
