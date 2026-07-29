import 'package:equatable/equatable.dart';

enum BackupRestoreMode { merge, replace }

enum BackupDataCategory {
  settings,
  quranUserData,
  reading,
  hifz,
  worship,
  library,
}

class BackupPreview extends Equatable {
  const BackupPreview({
    required this.schemaVersion,
    required this.createdAt,
    required this.categoryCounts,
  });

  final int schemaVersion;
  final DateTime createdAt;
  final Map<BackupDataCategory, int> categoryCounts;

  @override
  List<Object> get props => [schemaVersion, createdAt, categoryCounts];
}

class BackupRestoreResult extends Equatable {
  const BackupRestoreResult({
    required this.mode,
    required this.restoredCategories,
  });

  final BackupRestoreMode mode;
  final List<BackupDataCategory> restoredCategories;

  @override
  List<Object> get props => [mode, restoredCategories];
}
