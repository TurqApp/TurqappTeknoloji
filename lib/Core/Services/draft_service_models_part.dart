part of 'draft_service_library.dart';

class PostDraft {
  final String id;
  final String text;
  final List<String> imagePaths;
  final String? videoPath;
  final String location;
  final String gif;
  final bool commentEnabled;
  final int sharePrivacy;
  final DateTime lastModified;
  final DateTime? scheduledDate;

  PostDraft({
    required this.id,
    required this.text,
    required this.imagePaths,
    this.videoPath,
    required this.location,
    required this.gif,
    required this.commentEnabled,
    required this.sharePrivacy,
    required this.lastModified,
    this.scheduledDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'imagePaths': imagePaths,
        'videoPath': videoPath,
        'location': location,
        'gif': gif,
        'commentEnabled': commentEnabled,
        'sharePrivacy': sharePrivacy,
        'lastModified': lastModified.millisecondsSinceEpoch,
        'scheduledDate': scheduledDate?.millisecondsSinceEpoch,
      };

  factory PostDraft.fromJson(Map<String, dynamic> json) => PostDraft(
        id: json['id'],
        text: json['text'],
        imagePaths: List<String>.from(json['imagePaths']),
        videoPath: json['videoPath'],
        location: json['location'],
        gif: json['gif'],
        commentEnabled: json['commentEnabled'],
        sharePrivacy: json['sharePrivacy'],
        lastModified: DateTime.fromMillisecondsSinceEpoch(json['lastModified']),
        scheduledDate: json['scheduledDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['scheduledDate'])
            : null,
      );

  bool get isEmpty =>
      text.trim().isEmpty &&
      imagePaths.isEmpty &&
      videoPath == null &&
      gif.isEmpty;

  bool get hasMedia =>
      imagePaths.isNotEmpty || videoPath != null || gif.isNotEmpty;

  String get previewText {
    if (text.isNotEmpty) {
      return text.length > 50 ? '${text.substring(0, 50)}...' : text;
    }
    if (hasMedia) {
      final mediaCount = imagePaths.length +
          (videoPath != null ? 1 : 0) +
          (gif.isNotEmpty ? 1 : 0);
      return '$mediaCount medya dosyası';
    }
    return 'Boş taslak';
  }
}
