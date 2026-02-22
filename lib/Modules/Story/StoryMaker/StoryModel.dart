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
}
