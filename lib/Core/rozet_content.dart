import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';

Color mapRozetToColor(String rozetRaw) {
  final key = rozetRaw.trim().toLowerCase();
  switch (key) {
    case "kirmizi":
    case "kırmızı":
    case "red":
      return Colors.red;
    case "mavi":
    case "açık mavi":
    case "acik mavi":
    case "blue":
      return Colors.blue;
    case "sari":
    case "sarı":
    case "yellow":
      return Colors.orange;
    case "siyah":
    case "black":
      return Colors.black;
    case "gri":
    case "gray":
    case "grey":
      return Colors.grey;
    case "turkuaz":
    case "turquoise":
    case "cyan":
      return const Color(0xFF40E0D0);
    default:
      return Colors.transparent;
  }
}

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

  Future<void> _loadRozet() async {
    _pruneStaleCache();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final cachedColor = _badgeCache[userID];
    final cachedAt = _badgeCacheMs[userID] ?? 0;
    final isFresh = cachedColor != null &&
        cachedColor != Colors.transparent &&
        (nowMs - cachedAt) < _cacheTtlMs;
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
      final summary = await UserRepository.ensure().getUser(
        userID,
        preferCache: true,
        cacheOnly: false,
      );
      if (summary == null) {
        color.value = Colors.transparent;
        return;
      }
      final mapped = mapRozetToColor(summary.rozet);
      color.value = mapped;
      if (mapped == Colors.transparent) {
        _badgeCache.remove(userID);
        _badgeCacheMs.remove(userID);
      } else {
        _badgeCache[userID] = mapped;
        _badgeCacheMs[userID] = DateTime.now().millisecondsSinceEpoch;
      }
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
  final double leftSpacing;
  final String? rozetValue;

  const RozetContent({
    super.key,
    required this.size,
    required this.userID,
    this.leftSpacing = 3,
    this.rozetValue,
  });

  Widget _badge(Color color) {
    return Transform.translate(
      offset: const Offset(0, -1),
      child: Padding(
        padding: EdgeInsets.only(left: leftSpacing),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final knownRozet = (rozetValue ?? '').trim();
    if (knownRozet.isNotEmpty) {
      final mapped = mapRozetToColor(knownRozet);
      return mapped == Colors.transparent
          ? const SizedBox.shrink()
          : _badge(mapped);
    }

    if (userID.isEmpty) {
      return const SizedBox.shrink();
    }

    final tag = "rozet_$userID";
    final controller = Get.put(RozetController(userID), tag: tag);

    return Obx(() {
      final color = controller.color.value;
      return color == Colors.transparent
          ? const SizedBox.shrink()
          : _badge(color);
    });
  }
}
