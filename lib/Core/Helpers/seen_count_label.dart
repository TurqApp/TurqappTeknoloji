import 'package:flutter/material.dart';

// lib/services/post_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../formatters.dart';

class PostServiceExternal {
  /// Gönderinin görüntülenme sayısını döner
  static Future<int> calculateSeenCount(String postID) async {
    final doc = await FirebaseFirestore.instance
        .collection("Posts")
        .doc(postID)
        .get();
    final data = doc.data();
    if (data == null) return 0;
    final stats = data['stats'] as Map<String, dynamic>? ?? {};
    final dynamic raw = stats['statsCount'] ?? data['statsCount'];
    if (raw is int) return raw < 0 ? 0 : raw;
    if (raw is num) return raw.toInt() < 0 ? 0 : raw.toInt();
    return 0;
  }
}


class SeenCountLabel extends StatelessWidget {
  final String postID;
  const SeenCountLabel(this.postID, {super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: PostServiceExternal.calculateSeenCount(postID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('0');
        }
        if (snapshot.hasError) {
          return const Text('0');
        }
        // Veri geldiğinde:
        final count = snapshot.data ?? 0;
        return Text(
          NumberFormatter.format(count),
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontFamily: "MontserratBold",
            shadows: [
              Shadow(
                offset: Offset(1, 1),           // Gölgenin kayma mesafesi
                blurRadius: 2,                  // Gölgenin yayılma miktarı
                color: Colors.black.withValues(alpha: 0.6), // Yarı saydam siyah gölge
              ),
            ],
          ),
        );
      },
    );
  }
}
