import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RozetController extends GetxController {
  final String userID;
  RozetController(this.userID);

  Rx<Color> color = Colors.transparent.obs;
  static final Map<String, Color> _badgeCache = <String, Color>{};
  static final Map<String, int> _badgeCacheMs = <String, int>{};
  static const int _cacheTtlMs = 10 * 60 * 1000;
  static const int _staleRetentionMs = 30 * 60 * 1000;

  @override
  void onInit() {
    super.onInit();
    _loadRozet();
  }

  Color _mapRozetColor(String rozet) {
    switch (rozet) {
      case "Kirmizi":
        return Colors.red;
      case "Mavi":
        return Colors.blue;
      case "Sari":
        return Colors.orange;
      case "Siyah":
        return Colors.black;
      case "Gri":
        return Colors.grey;
      case "Turkuaz":
        return const Color(0xFF40E0D0);
      default:
        return Colors.transparent;
    }
  }

  Future<void> _loadRozet() async {
    _pruneStaleCache();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final cachedColor = _badgeCache[userID];
    final cachedAt = _badgeCacheMs[userID] ?? 0;
    final isFresh = cachedColor != null && (nowMs - cachedAt) < _cacheTtlMs;
    if (isFresh) {
      color.value = cachedColor;
      return;
    }
    if (cachedColor != null) {
      color.value = cachedColor;
    }
    await _fetchRozetOnce();
  }

  void _pruneStaleCache() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final staleKeys = <String>[];
    for (final entry in _badgeCacheMs.entries) {
      if ((nowMs - entry.value) > _staleRetentionMs) {
        staleKeys.add(entry.key);
      }
    }
    for (final key in staleKeys) {
      _badgeCacheMs.remove(key);
      _badgeCache.remove(key);
    }
  }

  Future<void> _fetchRozetOnce() async {
    try {
      DocumentSnapshot<Map<String, dynamic>>? doc;
      try {
        doc = await FirebaseFirestore.instance
            .collection("users")
            .doc(userID)
            .get(const GetOptions(source: Source.cache));
      } catch (_) {}
      doc ??= await FirebaseFirestore.instance
          .collection("users")
          .doc(userID)
          .get(const GetOptions(source: Source.serverAndCache));
      if (!doc.exists) {
        color.value = Colors.transparent;
        return;
      }
      final data = doc.data() ?? const <String, dynamic>{};
      final rozet = (data["rozet"] ?? "").toString();
      final mapped = _mapRozetColor(rozet);
      color.value = mapped;
      _badgeCache[userID] = mapped;
      _badgeCacheMs[userID] = DateTime.now().millisecondsSinceEpoch;
    } catch (_) {
      color.value = Colors.transparent;
    }
  }

  void updateUserID(String newUserID) {
    if (newUserID != userID) return;
    _loadRozet();
  }
}

class RozetContent extends StatelessWidget {
  final double size;
  final String userID;

  const RozetContent({
    super.key,
    required this.size,
    required this.userID,
  });

  @override
  Widget build(BuildContext context) {
    final tag = "rozet_$userID";
    final controller = Get.put(RozetController(userID), tag: tag);

    return Obx(() {
      final color = controller.color.value;
      return controller.color.value != Colors.transparent
          ? Transform.translate(
              offset: const Offset(0, -1),
              child: Stack(
                children: [
                  if (color != Colors.transparent)
                    Padding(
                      padding: const EdgeInsets.only(left: 3),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: size - 7,
                            height: size - 7,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Icon(
                            CupertinoIcons.checkmark_seal_fill,
                            color: color,
                            size: size,
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox(width: 2),
                ],
              ),
            )
          : SizedBox();
    });
  }
}
