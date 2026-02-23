import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'StoryMakerController.dart';

class StoryModel {
  final String id;
  final String userId;
  final DateTime createdAt;
  final Color backgroundColor;
  final String musicUrl;
  final List<StoryElement> elements;

  StoryModel({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.backgroundColor,
    required this.musicUrl,
    required this.elements,
  });

  /// Firestore dokümanından StoryModel’a dönüştürür
  factory StoryModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    // elements dizisini Map’lerden StoryElement nesnelerine dönüştür
    final elems =
        (data['elements'] as List).cast<Map<String, dynamic>>().map((m) {
      // Türü String’ten enum’a çevir
      final typeStr = m['type'] as String;
      final type = StoryElementType.values.firstWhere(
        (e) => e.toString().split('.').last == typeStr,
      );
      // Pozisyon
      final posMap = m['position'] as Map<String, dynamic>;
      final pos = Offset(
        (posMap['x'] as num).toDouble(),
        (posMap['y'] as num).toDouble(),
      );
      return StoryElement(
        type: type,
        content: m['content'] as String,
        width: (m['width'] as num).toDouble(),
        height: (m['height'] as num).toDouble(),
        position: pos,
        rotation: (m['rotation'] as num).toDouble(),
        zIndex: m['zIndex'] as int,
        isMuted: m['isMuted'] as bool,
        fontSize: (m['fontSize'] as num).toDouble(),
        aspectRatio: (m['aspectRatio'] as num?)?.toDouble() ??
            1.0, // Default 1.0 if missing
        textColor: (m['textColor'] as int?) ?? 0xFFFFFFFF,
        textBgColor: (m['textBgColor'] as int?) ?? 0x66000000,
        hasTextBg: (m['hasTextBg'] as bool?) ?? false,
        textAlign: (m['textAlign'] as String?) ?? 'center',
        fontWeight: (m['fontWeight'] as String?) ?? 'regular',
        italic: (m['italic'] as bool?) ?? false,
        underline: (m['underline'] as bool?) ?? false,
        shadowBlur: (m['shadowBlur'] as num?)?.toDouble() ?? 2.0,
        shadowOpacity: (m['shadowOpacity'] as num?)?.toDouble() ?? 0.6,
      );
    }).toList();

    // createdAt field'ının güvenli parsing'i
    DateTime parseCreatedAt() {
      final createdAtData = data['createdAt'];
      if (createdAtData is Timestamp) {
        return createdAtData.toDate();
      } else if (createdAtData is int) {
        return DateTime.fromMillisecondsSinceEpoch(createdAtData);
      } else {
        // Fallback - şimdiki zaman
        return DateTime.now();
      }
    }

    return StoryModel(
      id: doc.id,
      userId: data['userId'] as String,
      createdAt: parseCreatedAt(),
      backgroundColor: Color(data['backgroundColor'] as int),
      musicUrl: data['musicUrl'] as String? ?? "",
      elements: elems,
    );
  }

  /// StoryModel’ı Firestore’a yazmak üzere Map’e çevirir
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'backgroundColor': backgroundColor.value,
        'musicUrl': musicUrl,
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
              },
            )
            .toList(),
      };

  /// Yerel mini-cache için JSON-safe map.
  Map<String, dynamic> toCacheMap() => {
        'id': id,
        'userId': userId,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'backgroundColor': backgroundColor.value,
        'musicUrl': musicUrl,
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
              },
            )
            .toList(),
      };

  factory StoryModel.fromCacheMap(Map<String, dynamic> data) {
    final rawElements =
        (data['elements'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final elems = rawElements.map((m) {
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
        content: (m['content'] ?? '').toString(),
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
      );
    }).toList();

    return StoryModel(
      id: (data['id'] ?? '').toString(),
      userId: (data['userId'] ?? '').toString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          (data['createdAt'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch),
      backgroundColor:
          Color((data['backgroundColor'] as num?)?.toInt() ?? 0xFF000000),
      musicUrl: (data['musicUrl'] ?? '').toString(),
      elements: elems,
    );
  }
}
