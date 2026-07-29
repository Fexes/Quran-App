import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/theme/quran_theme.dart';
import '../../../../core/widgets/premium_surface.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/backup_models.dart';
import '../../domain/repositories/backup_repository.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  late final BackupRepository _repository;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _repository = getIt<BackupRepository>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).backupPrivacyTitle),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
            children: [
              const _PrivacySummary(),
              const SizedBox(height: 14),
              PremiumSurface(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Encrypted local backup',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Export a password-protected file, or preview and restore '
                      'one without sending private data to a server.',
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _busy ? null : _exportBackup,
                      icon: const Icon(Icons.file_upload_outlined),
                      label: const Text('Export encrypted backup'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _importBackup,
                      icon: const Icon(Icons.file_download_outlined),
                      label: const Text('Preview and restore backup'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              PremiumSurface(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Erase local data',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose one category, or erase all personal app data.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: QuranTheme.subText(context, 0.68),
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final category in BackupDataCategory.values)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(_categoryIcon(category)),
                        title: Text(_categoryLabel(category)),
                        subtitle: Text(_categoryDescription(category)),
                        trailing: const Icon(Icons.delete_outline_rounded),
                        onTap: _busy ? null : () => _eraseCategory(category),
                      ),
                    const Divider(height: 26),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: _busy ? null : _eraseAll,
                      icon: const Icon(Icons.delete_forever_rounded),
                      label: const Text('Erase all personal data'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_busy)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _exportBackup() async {
    final password = await _passwordDialog(confirm: true);
    if (password == null) {
      return;
    }
    await _perform(() async {
      final bytes = await _repository.createEncryptedBackup(password);
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save encrypted Quran backup',
        fileName: 'quran_backup_$date.quranbackup',
        type: FileType.custom,
        allowedExtensions: const ['quranbackup'],
        bytes: bytes,
      );
      if (savedPath == null && !kIsWeb) {
        return;
      }
      _showMessage('Encrypted backup exported. Keep its password safe.');
    });
  }

  Future<void> _importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Choose a Quran backup',
      type: FileType.custom,
      allowedExtensions: const ['quranbackup'],
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes == null) {
      if (result != null) {
        _showMessage('Could not read the selected backup.', error: true);
      }
      return;
    }
    if (!mounted) {
      return;
    }
    final password = await _passwordDialog();
    if (password == null) {
      return;
    }
    await _perform(() async {
      final preview = await _repository.inspectEncryptedBackup(bytes, password);
      if (!mounted) {
        return;
      }
      final mode = await _restorePreviewDialog(preview);
      if (mode == null) {
        return;
      }
      final restored = await _repository.restoreEncryptedBackup(
        bytes: bytes,
        password: password,
        mode: mode,
      );
      _showMessage(
        '${restored.restoredCategories.length} data categories restored. '
        'Reopen screens to refresh them.',
      );
    });
  }

  Future<void> _eraseCategory(BackupDataCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Erase ${_categoryLabel(category)}?'),
        content: Text(
          '${_categoryDescription(category)} This cannot be undone unless it '
          'exists in an exported backup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Erase'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await _perform(() async {
      await _repository.eraseCategory(category);
      _showMessage('${_categoryLabel(category)} erased.');
    });
  }

  Future<void> _eraseAll() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Erase all personal data?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bookmarks, notes, reading goals, Hifz progress, library data, '
              'prayer and fasting journal, and settings will be removed. '
              'Type ERASE to continue.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'ERASE'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim() == 'ERASE'),
            child: const Text('Erase all'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (confirmed != true) {
      return;
    }
    await _perform(() async {
      await _repository.eraseAllUserData();
      _showMessage('Personal data erased. Setup will reopen after restart.');
    });
  }

  Future<String?> _passwordDialog({bool confirm = false}) async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    String? validation;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(confirm ? 'Protect your backup' : 'Unlock backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  helperText: confirm ? 'At least 8 characters' : null,
                ),
              ),
              if (confirm) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                  ),
                ),
              ],
              if (validation != null) ...[
                const SizedBox(height: 10),
                Text(
                  validation!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final password = passwordController.text;
                if (password.length < 8) {
                  setDialogState(() {
                    validation = 'Use at least 8 characters.';
                  });
                  return;
                }
                if (confirm && password != confirmController.text) {
                  setDialogState(() {
                    validation = 'Passwords do not match.';
                  });
                  return;
                }
                Navigator.pop(dialogContext, password);
              },
              child: Text(confirm ? 'Continue' : 'Preview'),
            ),
          ],
        ),
      ),
    );
    passwordController.dispose();
    confirmController.dispose();
    return result;
  }

  Future<BackupRestoreMode?> _restorePreviewDialog(BackupPreview preview) {
    return showDialog<BackupRestoreMode>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Backup preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Created ${DateFormat.yMMMd().add_jm().format(preview.createdAt.toLocal())}',
            ),
            Text('Backup format version ${preview.schemaVersion}'),
            const SizedBox(height: 12),
            for (final entry in preview.categoryCounts.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    Expanded(child: Text(_categoryLabel(entry.key))),
                    Text('${entry.value} stored entries'),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            const Text(
              'Merge keeps newer local progress. Replace clears each included '
              'category before restoring it.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, BackupRestoreMode.replace),
            child: const Text('Replace'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, BackupRestoreMode.merge),
            child: const Text('Merge'),
          ),
        ],
      ),
    );
  }

  Future<void> _perform(Future<void> Function() operation) async {
    setState(() => _busy = true);
    try {
      await operation();
    } catch (error) {
      _showMessage(_friendlyError(error), error: true);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  String _friendlyError(Object error) {
    if (error is FormatException) {
      return error.message;
    }
    return 'The backup could not be processed. Check the file and password.';
  }
}

class _PrivacySummary extends StatelessWidget {
  const _PrivacySummary();

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user_outlined),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your personal data stays on this device',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Included: settings, bookmarks, notes, last read, reading goals, '
            'Hifz progress, prayer and fasting journal, and library activity.\n\n'
            'Excluded: downloaded translations, tafsir, Quran word data, audio, '
            'and public source files. These can be downloaded again.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: QuranTheme.subText(context, 0.72),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

String _categoryLabel(BackupDataCategory category) {
  return switch (category) {
    BackupDataCategory.settings => 'Settings',
    BackupDataCategory.quranUserData => 'Quran bookmarks & notes',
    BackupDataCategory.reading => 'Reading goals & plans',
    BackupDataCategory.hifz => 'Hifz progress',
    BackupDataCategory.worship => 'Prayer & fasting journal',
    BackupDataCategory.library => 'Hadith & Azkar activity',
  };
}

String _categoryDescription(BackupDataCategory category) {
  return switch (category) {
    BackupDataCategory.settings =>
      'Appearance, languages, prayer, and app choices',
    BackupDataCategory.quranUserData =>
      'Bookmarks, collections, notes, and last read',
    BackupDataCategory.reading => 'Daily progress, streaks, Khatma, and plans',
    BackupDataCategory.hifz => 'Collections, due reviews, and recall history',
    BackupDataCategory.worship => 'Prayer, Qada, pause, and fasting records',
    BackupDataCategory.library => 'Favorites and completion state',
  };
}

IconData _categoryIcon(BackupDataCategory category) {
  return switch (category) {
    BackupDataCategory.settings => Icons.tune_rounded,
    BackupDataCategory.quranUserData => Icons.bookmarks_outlined,
    BackupDataCategory.reading => Icons.track_changes_rounded,
    BackupDataCategory.hifz => Icons.psychology_alt_outlined,
    BackupDataCategory.worship => Icons.mosque_outlined,
    BackupDataCategory.library => Icons.local_library_outlined,
  };
}
