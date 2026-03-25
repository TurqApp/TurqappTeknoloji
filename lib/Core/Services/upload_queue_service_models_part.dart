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

  QueuedUpload({
    required this.id,
    required this.postData,
    required this.imagePaths,
    this.videoPath,
    required this.createdAt,
    this.status = UploadStatus.pending,
    this.retryCount = 0,
    this.errorMessage,
    this.progress = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'postData': postData,
        'imagePaths': imagePaths,
        'videoPath': videoPath,
        'createdDate': createdAt.millisecondsSinceEpoch,
        'status': status.name,
        'retryCount': retryCount,
        'errorMessage': errorMessage,
        'progress': progress,
      };

  factory QueuedUpload.fromJson(Map<String, dynamic> json) => QueuedUpload(
        id: json['id'],
        postData: json['postData'],
        imagePaths: List<String>.from(json['imagePaths']),
        videoPath: json['videoPath'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdDate']),
        status: UploadStatus.values.firstWhere((e) => e.name == json['status']),
        retryCount: json['retryCount'] ?? 0,
        errorMessage: json['errorMessage'],
        progress: json['progress']?.toDouble() ?? 0.0,
      );
}
