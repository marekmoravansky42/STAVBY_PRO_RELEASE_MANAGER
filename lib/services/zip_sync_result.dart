enum ZipSyncStatus { success, cancelled, error }

class ZipSyncResult {
  const ZipSyncResult.success() : status = ZipSyncStatus.success, message = 'Hotovo';
  const ZipSyncResult.cancelled() : status = ZipSyncStatus.cancelled, message = 'Preskočené používateľom';
  const ZipSyncResult.error(this.message) : status = ZipSyncStatus.error;

  final ZipSyncStatus status;
  final String message;

  Map<String, Object?> toCompletionStep() => {
    'name': 'Import vývojového ZIPu',
    'success': status != ZipSyncStatus.error,
    'skipped': status == ZipSyncStatus.cancelled,
    'message': message,
  };
}

Future<ZipSyncResult> selectAndSynchronizeZip({
  required Future<String?> Function() selectZip,
  required Future<ZipSyncResult> Function(String) synchronize,
}) async {
  final selected = await selectZip();
  if (selected == null || selected.trim().isEmpty) {
    return const ZipSyncResult.cancelled();
  }
  return synchronize(selected);
}
