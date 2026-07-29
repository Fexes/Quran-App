import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'di/injection.dart';
import 'observers/app_bloc_observer.dart';

typedef AppBuilder = Widget Function();

Future<void> bootstrap(AppBuilder builder) async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const AppBlocObserver();

  await _startApp(builder);
}

Future<void> _startApp(AppBuilder builder) async {
  try {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await configureDependencies();
    runApp(builder());
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'app bootstrap',
        context: ErrorDescription('while preparing local app services'),
      ),
    );
    runApp(
      _BootstrapFailureApp(
        message: kDebugMode ? error.toString() : null,
        onRetry: () => _startApp(builder),
      ),
    );
  }
}

class _BootstrapFailureApp extends StatelessWidget {
  const _BootstrapFailureApp({required this.onRetry, this.message});

  final Future<void> Function() onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storage_rounded, size: 42),
                  const SizedBox(height: 14),
                  Text(
                    'Quran could not finish starting',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your local data has not been erased. Check available storage and try again.',
                    textAlign: TextAlign.center,
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      message!,
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
