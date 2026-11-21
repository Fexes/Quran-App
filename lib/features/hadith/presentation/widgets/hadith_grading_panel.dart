import 'package:flutter/material.dart';

import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../domain/entities/hadith_item.dart';
import '../../domain/services/hadith_grading.dart';

String hadithTextReference(String value) {
  final text = value.trim();
  final uri = Uri.tryParse(text);
  return uri != null && uri.hasScheme && uri.hasAuthority ? '' : text;
}

class HadithGradingPanel extends StatelessWidget {
  const HadithGradingPanel({
    super.key,
    required this.grading,
    this.compact = false,
  });

  factory HadithGradingPanel.fromHadith({
    Key? key,
    required HadithItem hadith,
    bool compact = false,
  }) => HadithGradingPanel(
    key: key,
    grading: HadithGrading.fromHadith(hadith),
    compact: compact,
  );

  factory HadithGradingPanel.fromGrades({
    Key? key,
    required Iterable<Object?> grades,
    String fallbackGrade = '',
    String bookId = '',
    String sourceId = '',
    String reference = '',
    String sourceUrl = '',
    bool compact = false,
  }) => HadithGradingPanel(
    key: key,
    grading: HadithGrading.fromGrades(
      grades: grades,
      fallbackGrade: fallbackGrade,
      bookId: bookId,
      sourceId: sourceId,
      reference: reference,
      sourceUrl: sourceUrl,
    ),
    compact: compact,
  );

  final HadithGrading grading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final reference = hadithTextReference(grading.reference);
    final severe =
        grading.status == HadithGradingStatus.weak ||
        grading.status == HadithGradingStatus.fabricated;
    final color = severe
        ? theme.colorScheme.error
        : grading.requiresCaution
        ? QuranTheme.semantic(context).warning
        : QuranTheme.text(context);
    if (compact) {
      if (!grading.requiresCaution) return const SizedBox.shrink();
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: Semantics(
          button: true,
          child: Tooltip(
            message: switch (code) {
              'ur' => 'درج شدہ احکام دیکھیں',
              'ar' => 'عرض الأحكام المنقولة',
              _ => 'View reported grades',
            },
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AppSheet(
                    title: grading.labelFor(code),
                    child: HadithGradingPanel(grading: grading),
                  ),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  child: Align(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcon(
                            Icons.info_outline_rounded,
                            color: color,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              grading.labelFor(code),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: color,
                                fontSize: 11,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: grading.requiresCaution ? 0.09 : 0.035),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (grading.requiresCaution) ...[
                AppIcon(Icons.info_outline_rounded, color: color, size: 20),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  grading.labelFor(code),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (!compact || grading.requiresCaution) ...[
            const SizedBox(height: 6),
            Text(
              grading.explanationFor(code),
              style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
            ),
          ],
          if (!compact) ...[
            for (final assessment in grading.assessments) ...[
              const SizedBox(height: 12),
              if (assessment.grader.isNotEmpty)
                Text(assessment.grader, style: theme.textTheme.labelMedium),
              const SizedBox(height: 3),
              Text(
                assessment.grade,
                textDirection:
                    RegExp(r'[\u0600-\u06ff]').hasMatch(assessment.grade)
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (reference.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(reference, style: theme.textTheme.bodySmall),
            ],
          ],
        ],
      ),
    );
  }
}
