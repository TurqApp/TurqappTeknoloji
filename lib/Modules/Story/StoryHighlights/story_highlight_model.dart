import 'package:cloud_firestore/cloud_firestore.dart';

class StoryHighlightModel {
  final String id;
  final String userId;
  String title;
  String coverUrl;
  List<String> storyIds;
  final DateTime createdAt;
  int order;

  StoryHighlightModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.coverUrl,
    required this.storyIds,
    required this.createdAt,
    this.order = 0,
  });

  factory StoryHighlightModel.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return StoryHighlightModel(
      id: doc.id,
      userId: (data['userId'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      coverUrl: (data['coverUrl'] ?? '').toString(),
      storyIds: List<String>.from(data['storyIds'] ?? []),
      createdAt: data['createdDate'] is Timestamp
          ? (data['createdDate'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(
              (data['createdDate'] as num?)?.toInt() ??
                  DateTime.now().millisecondsSinceEpoch),
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'coverUrl': coverUrl,
        'storyIds': storyIds,
        'createdDate': DateTime.now().millisecondsSinceEpoch,
        'order': order,
      };
}
