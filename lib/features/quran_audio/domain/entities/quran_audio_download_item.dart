import 'package:equatable/equatable.dart';

enum QuranAudioDownloadStatus {
  notDownloaded,
  queued,
  downloading,
  paused,
  downloaded,
  failed,
  deleting,
}

enum QuranAudioDownloadScope { ayah, surah, page, reciter }

class QuranAudioDownloadItem extends Equatable {
  const QuranAudioDownloadItem({
    required this.id,
    required this.reciterId,
    required this.reciterName,
    required this.surahNumber,
    required this.ayahNumber,
    required this.verseKey,
    required this.page,
    required this.remoteUrl,
    required this.relativeDirectory,
    required this.filename,
    required this.status,
    required this.updatedAt,
    this.localUri,
    this.bytesDownloaded,
    this.bytesTotal,
    this.errorMessage,
    this.isBulkDownload = false,
    this.requestedSurahNumber,
  });

  factory QuranAudioDownloadItem.fromJson(Map<dynamic, dynamic> json) {
    return QuranAudioDownloadItem(
      id: _string(json['id']),
      reciterId: _string(json['reciterId']),
      reciterName: _string(json['reciterName']),
      surahNumber: _int(json['surahNumber']),
      ayahNumber: _int(json['ayahNumber']),
      verseKey: _string(json['verseKey']),
      page: _int(json['page']),
      remoteUrl: _string(json['remoteUrl']),
      relativeDirectory: _string(json['relativeDirectory']),
      filename: _string(json['filename']),
      localUri: _nullableString(json['localUri']),
      bytesDownloaded: _nullableInt(json['bytesDownloaded']),
      bytesTotal: _nullableInt(json['bytesTotal']),
      status: _status(json['status']),
      errorMessage: _nullableString(json['errorMessage']),
      isBulkDownload: json['isBulkDownload'] == true,
      requestedSurahNumber: _nullableInt(json['requestedSurahNumber']),
      updatedAt:
          DateTime.tryParse(_string(json['updatedAt'])) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final String id;
  final String reciterId;
  final String reciterName;
  final int surahNumber;
  final int ayahNumber;
  final String verseKey;
  final int page;
  final String remoteUrl;
  final String relativeDirectory;
  final String filename;
  final String? localUri;
  final int? bytesDownloaded;
  final int? bytesTotal;
  final QuranAudioDownloadStatus status;
  final String? errorMessage;
  final DateTime updatedAt;
  final bool isBulkDownload;
  final int? requestedSurahNumber;

  // Shared audio keeps its verse identity but belongs to the requesting job.
  int get downloadSurahNumber {
    final requested = requestedSurahNumber;
    return requested != null && requested >= 1 && requested <= 114
        ? requested
        : surahNumber;
  }

  bool get isDownloaded => status == QuranAudioDownloadStatus.downloaded;
  bool get isActive =>
      status == QuranAudioDownloadStatus.queued ||
      status == QuranAudioDownloadStatus.downloading;

  double get progress {
    final total = bytesTotal;
    final downloaded = bytesDownloaded;
    if (total == null || total <= 0 || downloaded == null) {
      return isDownloaded ? 1 : 0;
    }
    return (downloaded / total).clamp(0, 1).toDouble();
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'reciterId': reciterId,
      'reciterName': reciterName,
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'verseKey': verseKey,
      'page': page,
      'remoteUrl': remoteUrl,
      'relativeDirectory': relativeDirectory,
      'filename': filename,
      'localUri': localUri,
      'bytesDownloaded': bytesDownloaded,
      'bytesTotal': bytesTotal,
      'status': status.name,
      'errorMessage': errorMessage,
      'updatedAt': updatedAt.toIso8601String(),
      'isBulkDownload': isBulkDownload,
      'requestedSurahNumber': requestedSurahNumber,
    };
  }

  QuranAudioDownloadItem copyWith({
    String? id,
    String? reciterId,
    String? reciterName,
    int? surahNumber,
    int? ayahNumber,
    String? verseKey,
    int? page,
    String? remoteUrl,
    String? relativeDirectory,
    String? filename,
    String? localUri,
    int? bytesDownloaded,
    int? bytesTotal,
    QuranAudioDownloadStatus? status,
    String? errorMessage,
    DateTime? updatedAt,
    bool? isBulkDownload,
    int? requestedSurahNumber,
    bool clearLocalUri = false,
    bool clearBytes = false,
    bool clearError = false,
  }) {
    return QuranAudioDownloadItem(
      id: id ?? this.id,
      reciterId: reciterId ?? this.reciterId,
      reciterName: reciterName ?? this.reciterName,
      surahNumber: surahNumber ?? this.surahNumber,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      verseKey: verseKey ?? this.verseKey,
      page: page ?? this.page,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      relativeDirectory: relativeDirectory ?? this.relativeDirectory,
      filename: filename ?? this.filename,
      localUri: clearLocalUri ? null : localUri ?? this.localUri,
      bytesDownloaded: clearBytes
          ? null
          : bytesDownloaded ?? this.bytesDownloaded,
      bytesTotal: clearBytes ? null : bytesTotal ?? this.bytesTotal,
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      updatedAt: updatedAt ?? this.updatedAt,
      isBulkDownload: isBulkDownload ?? this.isBulkDownload,
      requestedSurahNumber: requestedSurahNumber ?? this.requestedSurahNumber,
    );
  }

  static String idFor({
    required String reciterId,
    required int surahNumber,
    required int ayahNumber,
  }) {
    final safeReciterId = reciterId.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
    return [
      safeReciterId,
      surahNumber.toString().padLeft(3, '0'),
      ayahNumber.toString().padLeft(3, '0'),
    ].join('_');
  }

  static String _string(Object? value) => value is String ? value : '';

  static String? _nullableString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return null;
  }

  static int _int(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    return 0;
  }

  static int? _nullableInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    return null;
  }

  static QuranAudioDownloadStatus _status(Object? value) {
    if (value is String) {
      for (final status in QuranAudioDownloadStatus.values) {
        if (status.name == value) {
          return status;
        }
      }
    }
    return QuranAudioDownloadStatus.notDownloaded;
  }

  @override
  List<Object?> get props => [
    id,
    reciterId,
    reciterName,
    surahNumber,
    ayahNumber,
    verseKey,
    page,
    remoteUrl,
    relativeDirectory,
    filename,
    localUri,
    bytesDownloaded,
    bytesTotal,
    status,
    errorMessage,
    updatedAt,
    isBulkDownload,
    requestedSurahNumber,
  ];
}

class QuranAudioDownloadGroup extends Equatable {
  const QuranAudioDownloadGroup({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.reciterId,
    required this.scope,
    required this.totalAyahs,
    required this.downloadedAyahs,
    required this.failedAyahs,
    required this.queuedAyahs,
    required this.downloadingAyahs,
    required this.bytesDownloaded,
    required this.bytesTotal,
    required this.items,
    this.surahNumber,
  });

  final String id;
  final String title;
  final String subtitle;
  final String reciterId;
  final QuranAudioDownloadScope scope;
  final int? surahNumber;
  final int totalAyahs;
  final int downloadedAyahs;
  final int failedAyahs;
  final int queuedAyahs;
  final int downloadingAyahs;
  final int bytesDownloaded;
  final int bytesTotal;
  final List<QuranAudioDownloadItem> items;

  bool get isDownloaded => totalAyahs > 0 && downloadedAyahs >= totalAyahs;
  bool get isActive => queuedAyahs > 0 || downloadingAyahs > 0;
  bool get hasFailures => failedAyahs > 0;

  double get progress {
    if (totalAyahs <= 0) {
      return 0;
    }
    return (downloadedAyahs / totalAyahs).clamp(0, 1).toDouble();
  }

  @override
  List<Object?> get props => [
    id,
    title,
    subtitle,
    reciterId,
    scope,
    surahNumber,
    totalAyahs,
    downloadedAyahs,
    failedAyahs,
    queuedAyahs,
    downloadingAyahs,
    bytesDownloaded,
    bytesTotal,
    items,
  ];
}
