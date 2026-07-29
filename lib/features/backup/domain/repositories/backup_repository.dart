import 'dart:typed_data';

import '../entities/backup_models.dart';

abstract interface class BackupRepository {
  Future<Uint8List> createEncryptedBackup(String password);

  Future<BackupPreview> inspectEncryptedBackup(
    Uint8List bytes,
    String password,
  );

  Future<BackupRestoreResult> restoreEncryptedBackup({
    required Uint8List bytes,
    required String password,
    required BackupRestoreMode mode,
  });

  Future<void> eraseCategory(BackupDataCategory category);

  Future<void> eraseAllUserData();
}
