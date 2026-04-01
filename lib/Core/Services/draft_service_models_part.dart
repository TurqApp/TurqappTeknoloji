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

  static List<String> _cloneStringList(List<String> source) =>
      List<String>.from(source, growable: false);

  static String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  static bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      switch (value.trim().toLowerCase()) {
        case 'true':
        case '1':
        case 'yes':
        case 'evet':
          return true;
        case 'false':
        case '0':
        case 'no':
        case 'hayir':
        case 'hayır':
          return false;
      }
    }
    return fallback;
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  PostDraft({
    required this.id,
    required this.text,
    required List<String> imagePaths,
    this.videoPath,
    required this.location,
    required this.gif,
    required this.commentEnabled,
    required this.sharePrivacy,
    required this.lastModified,
    this.scheduledDate,
  }) : imagePaths = _cloneStringList(imagePaths);

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'imagePaths': List<String>.from(imagePaths, growable: false),
        'videoPath': videoPath,
        'location': location,
        'gif': gif,
        'commentEnabled': commentEnabled,
        'sharePrivacy': sharePrivacy,
        'lastModified': lastModified.millisecondsSinceEpoch,
        'scheduledDate': scheduledDate?.millisecondsSinceEpoch,
      };

  factory PostDraft.fromJson(Map<String, dynamic> json) => PostDraft(
        id: _asString(json['id']),
        text: _asString(json['text']),
        imagePaths: _asStringList(json['imagePaths']),
        videoPath: _asString(json['videoPath'], fallback: '').isEmpty
            ? null
            : _asString(json['videoPath']),
        location: _asString(json['location']),
        gif: _asString(json['gif']),
        commentEnabled: _asBool(json['commentEnabled']),
        sharePrivacy: _asInt(json['sharePrivacy']),
        lastModified: DateTime.fromMillisecondsSinceEpoch(
          _asInt(json['lastModified']),
        ),
        scheduledDate: json['scheduledDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(_asInt(json['scheduledDate']))
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
