import 'package:flutter/material.dart';

// lib/services/post_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../formatters.dart';

class _SeenCountCacheEntry {
  final int value;
  final int fetchedAtMs;

  const _SeenCountCacheEntry({
    required this.value,
    required this.fetchedAtMs,
  });
}

class PostServiceExternal {
  static const Duration _cacheTtl = Duration(minutes: 2);
  static final Map<String, _SeenCountCacheEntry> _cache = {};

  /// Gönderinin görüntülenme sayısını döner
  static Future<int> calculateSeenCount(String postID) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final cached = _cache[postID];
    if (cached != null && nowMs - cached.fetchedAtMs <= _cacheTtl.inMilliseconds) {
      return cached.value;
    }

    final doc =
        await FirebaseFirestore.instance.collection("Posts").doc(postID).get();
    final data = doc.data();
    if (data == null) return 0;
    final stats = data['stats'] as Map<String, dynamic>? ?? {};
    final dynamic raw = stats['statsCount'] ?? data['statsCount'];
    int count;
    if (raw is int) {
      count = raw < 0 ? 0 : raw;
    } else if (raw is num) {
      final v = raw.toInt();
      count = v < 0 ? 0 : v;
    } else {
      count = 0;
    }

    _cache[postID] = _SeenCountCacheEntry(value: count, fetchedAtMs: nowMs);
    return count;
  }
}

class SeenCountLabel extends StatefulWidget {
  final String postID;
  const SeenCountLabel(this.postID, {super.key});

  @override
  State<SeenCountLabel> createState() => _SeenCountLabelState();
}

class _SeenCountLabelState extends State<SeenCountLabel> {
  late final Future<int> _seenCountFuture;

  @override
  void initState() {
    super.initState();
    _seenCountFuture = PostServiceExternal.calculateSeenCount(widget.postID);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _seenCountFuture,
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
                offset: Offset(1, 1), // Gölgenin kayma mesafesi
                blurRadius: 2, // Gölgenin yayılma miktarı
                color: Colors.black
                    .withValues(alpha: 0.6), // Yarı saydam siyah gölge
              ),
            ],
          ),
        );
      },
    );
  }
}
