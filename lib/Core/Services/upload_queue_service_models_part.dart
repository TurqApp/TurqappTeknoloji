part of 'upload_queue_service.dart';

enum UploadStatus {
  pending('upload_queue.status_pending'),
  uploading('upload_queue.status_uploading'),
  completed('upload_queue.status_completed'),
  failed('upload_queue.status_failed'),
  paused('upload_queue.status_paused');

  const UploadStatus(this.labelKey);
  final String labelKey;

  String get label => labelKey.tr;
}

class QueuedUpload {
  final String id;
  final String postData;
  final List<String> imagePaths;
  final String? videoPath;
  final DateTime createdAt;
  UploadStatus status;
  int retryCount;
  String? errorMessage;
  double progress;

  static List<String> _cloneStringList(List<String> source) =>
      List<String>.from(source, growable: false);

  static String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final normalized = value.toString().trim();
    return normalized.isEmpty ? fallback : normalized;
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  static double _asDouble(dynamic value, {double fallback = 0.0}) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  static UploadStatus _asStatus(dynamic value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return UploadStatus.pending;
    return UploadStatus.values.firstWhere(
      (status) => status.name == raw,
      orElse: () => UploadStatus.pending,
    );
  }

  QueuedUpload({
    required this.id,
    required this.postData,
    required List<String> imagePaths,
    this.videoPath,
    required this.createdAt,
    this.status = UploadStatus.pending,
    this.retryCount = 0,
    this.errorMessage,
    this.progress = 0.0,
  }) : imagePaths = _cloneStringList(imagePaths);

  Map<String, dynamic> toJson() => {
        'id': id,
        'postData': postData,
        'imagePaths': _cloneStringList(imagePaths),
        'videoPath': videoPath,
        'createdDate': createdAt.millisecondsSinceEpoch,
        'status': status.name,
        'retryCount': retryCount,
        'errorMessage': errorMessage,
        'progress': progress,
      };

  factory QueuedUpload.fromJson(Map<String, dynamic> json) => QueuedUpload(
        id: _asString(json['id']),
        postData: _asString(json['postData']),
        imagePaths: _asStringList(json['imagePaths']),
        videoPath: _asString(json['videoPath'], fallback: '').isEmpty
            ? null
            : _asString(json['videoPath']),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          _asInt(json['createdDate']),
        ),
        status: _asStatus(json['status']),
        retryCount: _asInt(json['retryCount']),
        errorMessage: _asString(json['errorMessage'], fallback: '').isEmpty
            ? null
            : _asString(json['errorMessage']),
        progress: _asDouble(json['progress']),
      );
}
