import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../cubit/quran_interlinear_setup_cubit.dart';
import '../cubit/quran_interlinear_setup_state.dart';

class QuranInterlinearSetupGate extends StatefulWidget {
  const QuranInterlinearSetupGate({super.key, required this.child});

  final Widget child;

  @override
  State<QuranInterlinearSetupGate> createState() =>
      _QuranInterlinearSetupGateState();
}

class _QuranInterlinearSetupGateState extends State<QuranInterlinearSetupGate> {
  bool _sheetOpen = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<QuranInterlinearSetupCubit, QuranInterlinearSetupState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == QuranInterlinearSetupStatus.prompt && !_sheetOpen) {
          _sheetOpen = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) {
              return;
            }
            await _showStartupInterlinearSheet(context);
            if (mounted) {
              _sheetOpen = false;
            }
          });
        }
      },
      child: widget.child,
    );
  }
}

Future<bool> showRequiredInterlinearDownloadSheet(BuildContext context) async {
  final cubit = context.read<QuranInterlinearSetupCubit>();
  final complete = await cubit.hasFullCache();
  if (complete) {
    return true;
  }
  if (!context.mounted) {
    return false;
  }
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const _InterlinearDownloadSheet(requiredDownload: true),
    ),
  );
  return result ?? false;
}

Future<void> _showStartupInterlinearSheet(BuildContext context) {
  final cubit = context.read<QuranInterlinearSetupCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const _InterlinearDownloadSheet(requiredDownload: false),
    ),
  );
}

class _InterlinearDownloadSheet extends StatelessWidget {
  const _InterlinearDownloadSheet({required this.requiredDownload});

  final bool requiredDownload;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuranInterlinearSetupCubit, QuranInterlinearSetupState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == QuranInterlinearSetupStatus.complete) {
          Navigator.of(context).pop(true);
        }
        if (state.status == QuranInterlinearSetupStatus.ready) {
          Navigator.of(context).pop(false);
        }
      },
      builder: (context, state) {
        final downloading =
            state.status == QuranInterlinearSetupStatus.downloading;
        final progress = state.progress;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: PremiumSurface(
            radius: QuranTheme.radiusSheet,
            prominent: true,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: QuranTheme.outline(context),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: QuranTheme.softFill(
                          context,
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      child: const Icon(Icons.translate_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Download Quran translations',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  requiredDownload
                      ? 'Line-by-line Combined layout translation needs the full offline word cache first.'
                      : 'This enables line-by-line Combined layout translation offline. You can skip now and download later from reader settings.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: QuranTheme.subText(context, 0.72),
                    height: 1.35,
                  ),
                ),
                if (downloading || progress != null) ...[
                  const SizedBox(height: 18),
                  LinearProgressIndicator(value: progress?.percent),
                  const SizedBox(height: 8),
                  Text(
                    progress == null
                        ? 'Preparing download...'
                        : '${progress.completedPages} of ${progress.totalPages} pages downloaded',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: QuranTheme.subText(context, 0.66),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                if (state.status == QuranInterlinearSetupStatus.failure) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage ?? 'Download failed.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    if (!requiredDownload)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: downloading
                              ? null
                              : () => context
                                    .read<QuranInterlinearSetupCubit>()
                                    .skipForNow(),
                          child: const Text('Skip for now'),
                        ),
                      )
                    else
                      Expanded(
                        child: OutlinedButton(
                          onPressed: downloading
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: const Text('Close'),
                        ),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: downloading
                            ? null
                            : () => context
                                  .read<QuranInterlinearSetupCubit>()
                                  .download(),
                        child: Text(
                          state.status == QuranInterlinearSetupStatus.failure
                              ? 'Retry'
                              : 'Download now',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
