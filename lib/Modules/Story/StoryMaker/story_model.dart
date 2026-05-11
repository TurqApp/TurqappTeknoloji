import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'story_maker_controller.dart';

class StoryModel {
  final String id;
  final String userId;
  final DateTime createdAt;
  final Color backgroundColor;
  final String musicId;
  final String musicUrl;
  final String musicTitle;
  final String musicArtist;
  final String musicCoverUrl;
  final String hlsVideoUrl;
  final String shortId;
  final String shortUrl;
  final List<StoryElement> elements;

  StoryModel({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.backgroundColor,
    required this.musicId,
    required this.musicUrl,
    required this.musicTitle,
    required this.musicArtist,
    required this.musicCoverUrl,
    required this.hlsVideoUrl,
    this.shortId = '',
    this.shortUrl = '',
    required this.elements,
  });

  /// Firestore dokümanından StoryModel’a dönüştürür
  factory StoryModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data() ?? const {});
    final createdDate = data['createdDate'];
    if (createdDate is Timestamp) {
      data['createdDate'] = createdDate.millisecondsSinceEpoch;
    }
    data['id'] = doc.id;
    return StoryModel.fromCacheMap(data);
  }

  /// StoryModel’ı Firestore’a yazmak üzere Map’e çevirir
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'createdDate': DateTime.now().millisecondsSinceEpoch,
        'backgroundColor': backgroundColor.toARGB32(),
        'musicId': musicId,
        'musicUrl': musicUrl,
        'musicTitle': musicTitle,
        'musicArtist': musicArtist,
        'musicCoverUrl': musicCoverUrl,
        'hlsVideoUrl': hlsVideoUrl,
        'shortId': shortId,
        'shortUrl': shortUrl,
        'elements': elements
            .map(
              (e) => {
                'type': e.type.toString().split('.').last,
                'content': e.content,
                'width': e.width,
                'height': e.height,
                'position': {'x': e.position.dx, 'y': e.position.dy},
                'rotation': e.rotation,
                'zIndex': e.zIndex,
                'isMuted': e.isMuted,
                'fontSize': e.fontSize,
                'aspectRatio': e.aspectRatio,
                'textColor': e.textColor,
                'textBgColor': e.textBgColor,
                'hasTextBg': e.hasTextBg,
                'textAlign': e.textAlign,
                'fontWeight': e.fontWeight,
                'italic': e.italic,
                'underline': e.underline,
                'shadowBlur': e.shadowBlur,
                'shadowOpacity': e.shadowOpacity,
                'fontFamily': e.fontFamily,
                'hasOutline': e.hasOutline,
                'outlineColor': e.outlineColor,
                'stickerType': e.stickerType,
                'stickerData': e.stickerData,
                'mediaLookPreset': e.mediaLookPreset,
              },
            )
            .toList(),
      };

  /// Yerel mini-cache için JSON-safe map.
  Map<String, dynamic> toCacheMap() => {
        'id': id,
        'userId': userId,
        'createdDate': createdAt.millisecondsSinceEpoch,
        'backgroundColor': backgroundColor.toARGB32(),
        'musicId': musicId,
        'musicUrl': musicUrl,
        'musicTitle': musicTitle,
        'musicArtist': musicArtist,
        'musicCoverUrl': musicCoverUrl,
        'hlsVideoUrl': hlsVideoUrl,
        'elements': elements
            .map(
              (e) => {
                'type': e.type.toString().split('.').last,
                'content': e.content,
                'width': e.width,
                'height': e.height,
                'position': {'x': e.position.dx, 'y': e.position.dy},
                'rotation': e.rotation,
                'zIndex': e.zIndex,
                'isMuted': e.isMuted,
                'fontSize': e.fontSize,
                'aspectRatio': e.aspectRatio,
                'textColor': e.textColor,
                'textBgColor': e.textBgColor,
                'hasTextBg': e.hasTextBg,
                'textAlign': e.textAlign,
                'fontWeight': e.fontWeight,
                'italic': e.italic,
                'underline': e.underline,
                'shadowBlur': e.shadowBlur,
                'shadowOpacity': e.shadowOpacity,
                'fontFamily': e.fontFamily,
                'hasOutline': e.hasOutline,
                'outlineColor': e.outlineColor,
                'stickerType': e.stickerType,
                'stickerData': e.stickerData,
                'mediaLookPreset': e.mediaLookPreset,
              },
            )
            .toList(),
      };

  factory StoryModel.fromCacheMap(Map<String, dynamic> data) {
    final normalizedHlsVideoUrl = (data['hlsVideoUrl'] ?? '').toString().trim();
    final rawElements = data['elements'];
    final elementItems = rawElements is List ? rawElements : const [];
    final elems = elementItems.whereType<Map>().map((raw) {
      final m = raw.map((key, value) => MapEntry('$key', value));
      final typeStr = (m['type'] ?? 'text').toString();
      final type = StoryElementType.values.firstWhere(
        (e) => e.toString().split('.').last == typeStr,
        orElse: () => StoryElementType.text,
      );
      final posMap = (m['position'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final pos = Offset(
        (posMap['x'] as num?)?.toDouble() ?? 0.0,
        (posMap['y'] as num?)?.toDouble() ?? 0.0,
      );
      return StoryElement(
        type: type,
        content:
            type == StoryElementType.video && normalizedHlsVideoUrl.isNotEmpty
                ? normalizedHlsVideoUrl
                : (m['content'] ?? '').toString(),
        width: (m['width'] as num?)?.toDouble() ?? 0.0,
        height: (m['height'] as num?)?.toDouble() ?? 0.0,
        position: pos,
        rotation: (m['rotation'] as num?)?.toDouble() ?? 0.0,
        zIndex: (m['zIndex'] as num?)?.toInt() ?? 0,
        isMuted: (m['isMuted'] ?? false) == true,
        fontSize: (m['fontSize'] as num?)?.toDouble() ?? 16.0,
        aspectRatio: (m['aspectRatio'] as num?)?.toDouble() ?? 1.0,
        textColor: (m['textColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
        textBgColor: (m['textBgColor'] as num?)?.toInt() ?? 0x66000000,
        hasTextBg: (m['hasTextBg'] ?? false) == true,
        textAlign: (m['textAlign'] ?? 'center').toString(),
        fontWeight: (m['fontWeight'] ?? 'regular').toString(),
        italic: (m['italic'] ?? false) == true,
        underline: (m['underline'] ?? false) == true,
        shadowBlur: (m['shadowBlur'] as num?)?.toDouble() ?? 2.0,
        shadowOpacity: (m['shadowOpacity'] as num?)?.toDouble() ?? 0.6,
        fontFamily: (m['fontFamily'] ?? 'MontserratMedium').toString(),
        hasOutline: (m['hasOutline'] ?? false) == true,
        outlineColor: (m['outlineColor'] as num?)?.toInt() ?? 0xFF000000,
        stickerType: (m['stickerType'] ?? '').toString(),
        stickerData: (m['stickerData'] ?? '').toString(),
        mediaLookPreset: (m['mediaLookPreset'] ?? 'original').toString(),
      );
    }).toList();

    return StoryModel(
      id: (data['id'] ?? '').toString(),
      userId: (data['userId'] ?? '').toString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          (data['createdDate'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch),
      backgroundColor:
          Color((data['backgroundColor'] as num?)?.toInt() ?? 0xFF000000),
      musicId: (data['musicId'] ?? '').toString(),
      musicUrl: (data['musicUrl'] ?? '').toString(),
      musicTitle: (data['musicTitle'] ?? '').toString(),
      musicArtist: (data['musicArtist'] ?? '').toString(),
      musicCoverUrl: (data['musicCoverUrl'] ?? '').toString(),
      hlsVideoUrl: normalizedHlsVideoUrl,
      shortId: (data['shortId'] ?? '').toString(),
      shortUrl: (data['shortUrl'] ?? '').toString(),
      elements: elems,
    );
  }
}
