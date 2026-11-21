import 'package:flutter/material.dart';
import 'package:hijri_calendar/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../domain/entities/prayer_tracking_models.dart';
import '../../domain/repositories/prayer_tracking_repository.dart';

Future<bool> showFastingLogSheet(
  BuildContext context, {
  required DateTime date,
  FastingRecord? initial,
  FastStatus? initialStatus,
}) async {
  final today = DateUtils.dateOnly(DateTime.now());
  if (DateUtils.dateOnly(date).isAfter(today)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You can log a fast once its date arrives.'),
      ),
    );
    return false;
  }
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (_) => _FastingLogSheet(
          date: DateUtils.dateOnly(date),
          initial: initial,
          initialStatus: initialStatus,
        ),
      ) ??
      false;
}

String fastingTypeLabel(FastType type) => switch (type) {
  FastType.ramadan => 'Ramadan',
  FastType.voluntary => 'Voluntary',
  FastType.makeup => 'Make-up',
};

String fastingStatusLabel(FastStatus status) => switch (status) {
  FastStatus.completed => 'Completed',
  FastStatus.missed => 'Not completed',
  FastStatus.exempt => 'Exempt',
};

class _FastingLogSheet extends StatefulWidget {
  const _FastingLogSheet({
    required this.date,
    required this.initial,
    required this.initialStatus,
  });

  final DateTime date;
  final FastingRecord? initial;
  final FastStatus? initialStatus;

  @override
  State<_FastingLogSheet> createState() => _FastingLogSheetState();
}

class _FastingLogSheetState extends State<_FastingLogSheet> {
  late final _repository = getIt<PrayerTrackingRepository>();
  late FastType _type =
      widget.initial?.type ??
      (HijriCalendarConfig.fromGregorian(widget.date).hMonth == 9
          ? FastType.ramadan
          : FastType.voluntary);
  late FastStatus? _status = widget.initialStatus ?? widget.initial?.status;
  bool _saving = false;
  String? _error;

  void _close() {
    if (!_saving) Navigator.of(context).pop(false);
  }

  Future<void> _save({bool remove = false}) async {
    if (_saving || (!remove && _status == null)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (remove) {
        await _repository.removeFast(widget.date);
      } else {
        await _repository.saveFast(
          date: widget.date,
          type: _type,
          status: _status!,
        );
      }
      if (mounted) {
        setState(() => _saving = false);
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = remove
              ? 'The entry could not be removed. Please try again.'
              : 'Your fast could not be saved. Please try again.';
        });
      }
    }
  }

  Future<void> _remove() async {
    if (_saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove this entry?'),
        content: Text(
          'The fasting record for ${DateFormat.yMMMd().format(widget.date)} '
          'will be removed from your journal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep entry'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _save(remove: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_saving,
      child: AppSheet(
        title: widget.initial == null ? 'Log a fast' : 'Edit your fast',
        subtitle: DateFormat.yMMMMEEEEd().format(widget.date),
        onClose: _close,
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              onPressed: _saving || _status == null ? null : () => _save(),
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const AppIcon(Icons.check_rounded, size: 20),
              label: Text(_saving ? 'Saving…' : 'Save fast'),
            ),
            if (widget.initial != null)
              TextButton(
                onPressed: _saving ? null : _remove,
                child: const Text('Remove entry'),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Text('What kind of fast?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in FastType.values)
                  ChoiceChip(
                    showCheckmark: false,
                    label: Text(fastingTypeLabel(type)),
                    selected: _type == type,
                    onSelected: _saving
                        ? null
                        : (_) => setState(() => _type = type),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('How did it go?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Choose one outcome for this day.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: QuranTheme.subText(context),
              ),
            ),
            const SizedBox(height: 12),
            for (final status in FastStatus.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Semantics(
                  button: true,
                  selected: _status == status,
                  enabled: !_saving,
                  child: PremiumSurface(
                    onTap: _saving
                        ? null
                        : () => setState(() => _status = status),
                    padding: const EdgeInsets.all(14),
                    radius: QuranTheme.radiusControl,
                    borderColor: _status == status
                        ? theme.colorScheme.primary
                        : QuranTheme.outline(context),
                    borderWidth: _status == status ? 1.3 : 0.8,
                    child: Row(
                      children: [
                        AppIcon(switch (status) {
                          FastStatus.completed => Icons.check_circle_outline,
                          FastStatus.missed => Icons.remove_circle_outline,
                          FastStatus.exempt => Icons.pause_circle_outline,
                        }, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fastingStatusLabel(status),
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                switch (status) {
                                  FastStatus.completed =>
                                    'I completed this fast.',
                                  FastStatus.missed =>
                                    'I did not complete this fast.',
                                  FastStatus.exempt =>
                                    'I was exempt from fasting.',
                                },
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: QuranTheme.subText(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_status == status) ...[
                          const SizedBox(width: 8),
                          const AppIcon(Icons.check_rounded, size: 18),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
