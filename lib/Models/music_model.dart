import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

class MusicModel {
  final String docID;
  final String title;
  final String artist;
  final String audioUrl;
  final String coverUrl;
  final int durationMs;
  final int useCount;
  final int shareCount;
  final int storyCount;
  final int order;
  final int lastUsedAt;
  final int createdAt;
  final int updatedAt;
  final bool isActive;
  final String category;

  const MusicModel({
    required this.docID,
    required this.title,
    required this.artist,
    required this.audioUrl,
    required this.coverUrl,
    required this.durationMs,
    required this.useCount,
    required this.shareCount,
    required this.storyCount,
    required this.order,
    required this.lastUsedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.category,
  });

  bool get hasDisplayArtist => displayArtist.isNotEmpty;

  String get displayArtist {
    final cleanArtist = artist.trim();
    if (cleanArtist.isEmpty) return '';
    final normalized = normalizeSearchText(cleanArtist);
    if (normalized == 'turqapp müzik' || normalized == 'turqapp muzik') {
      return '';
    }
    return cleanArtist;
  }

  String get label {
    final cleanArtist = displayArtist;
    if (cleanArtist.isEmpty) return title;
    return '$title • $cleanArtist';
  }

  factory MusicModel.fromMap(Map<String, dynamic> data, String docID) {
    int parseInt(dynamic value, [int fallback = 0]) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    return MusicModel(
      docID: docID,
      title: (data['title'] ?? '').toString().trim(),
      artist: (data['artist'] ?? '').toString().trim(),
      audioUrl: (data['audioUrl'] ?? data['url'] ?? '').toString().trim(),
      coverUrl: (data['coverUrl'] ?? '').toString().trim(),
      durationMs: parseInt(data['durationMs']),
      useCount: parseInt(data['useCount'] ?? data['counter']),
      shareCount: parseInt(data['shareCount']),
      storyCount: parseInt(data['storyCount']),
      order: parseInt(data['order']),
      lastUsedAt: parseInt(data['lastUsedAt']),
      createdAt: parseInt(data['createdAt']),
      updatedAt: parseInt(data['updatedAt']),
      isActive: (data['isActive'] ?? true) == true,
      category: (data['category'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'artist': artist,
      'audioUrl': audioUrl,
      'coverUrl': coverUrl,
      'durationMs': durationMs,
      'useCount': useCount,
      'shareCount': shareCount,
      'storyCount': storyCount,
      'order': order,
      'lastUsedAt': lastUsedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
      'category': category,
    };
  }

  Map<String, dynamic> toCacheMap() {
    return {
      'docID': docID,
      ...toMap(),
    };
  }

  factory MusicModel.fromCacheMap(Map<String, dynamic> data) {
    return MusicModel.fromMap(
      data,
      (data['docID'] ?? '').toString(),
    );
  }
}
