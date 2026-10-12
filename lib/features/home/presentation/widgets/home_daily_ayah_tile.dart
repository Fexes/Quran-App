import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/theme/quran_theme_cubit.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../quran/presentation/widgets/quran_translation_text.dart';
import '../../domain/entities/daily_ayah.dart';
import 'daily_ayah_share_sheet.dart';

class HomeDailyAyahTile extends StatelessWidget {
  const HomeDailyAyahTile({
    super.key,
    required this.dailyAyah,
    required this.loading,
    required this.errorMessage,
    required this.onRetry,
  });

  final DailyAyah? dailyAyah;
  final bool loading;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final item = dailyAyah;
    return PremiumSurface(
      borderColor: QuranTheme.outline(context).withValues(alpha: 0.75),
      borderWidth: 0.6,
      onTap: item == null
          ? null
          : () => context.push(
              AppRoutes.quranReaderPath(
                item.surah.number,
                ayahNumber: item.ayah.number,
              ),
            ),
      padding: const EdgeInsets.all(18),
      color: QuranTheme.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const AppIcon(
                Icons.wb_sunny_rounded,
                color: Color(0xFFD19A16),
                size: 20,
                strokeWidth: 1.1,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verse of the Day',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: QuranTheme.subText(context, 0.68),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (item == null) ...[
            const SizedBox(height: 22),
            _DailyAyahStatus(
              loading: loading,
              errorMessage: errorMessage,
              onRetry: onRetry,
            ),
          ] else ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: QuranTheme.outline(context)),
                  ),
                  child: Text(
                    item.ayah.number.toString(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: Text(
                    item.ayah.textForScript(
                      context.watch<QuranThemeCubit>().state.quranArabicScript,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: ui.TextDirection.rtl,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      height: 1.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            QuranTranslationText(
              text: item.translation,
              resource: item.translationResource,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: QuranTheme.subText(context, 0.72),
                height: 1.55,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.reference,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => showDailyAyahShareSheet(context, item),
                  icon: const AppIcon(Icons.share_rounded, size: 19),
                  label: const Text('Share'),
                  style: TextButton.styleFrom(
                    foregroundColor: QuranTheme.subText(context, 0.72),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.push(
                    AppRoutes.quranReaderPath(
                      item.surah.number,
                      ayahNumber: item.ayah.number,
                    ),
                  ),
                  iconAlignment: IconAlignment.end,
                  icon: const AppIcon(Icons.chevron_right_rounded),
                  label: const Text('View Surah'),
                  style: TextButton.styleFrom(
                    foregroundColor: primary,
                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DailyAyahStatus extends StatelessWidget {
  const _DailyAyahStatus({
    required this.loading,
    required this.errorMessage,
    required this.onRetry,
  });

  final bool loading;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = errorMessage;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        children: [
          if (loading && message == null)
            const SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            )
          else
            AppIcon(
              Icons.menu_book_rounded,
              size: 34,
              color: Theme.of(context).colorScheme.primary,
            ),
          const SizedBox(height: 10),
          Text(
            message ?? 'Selecting today\'s ayah',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: QuranTheme.subText(context, 0.66),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const AppIcon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}
