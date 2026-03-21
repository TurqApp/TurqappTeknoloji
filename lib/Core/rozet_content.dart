import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/rozet_permissions.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';

Color mapRozetToColor(String rozetRaw) {
  final key = normalizeRozetValue(rozetRaw);
  switch (key) {
    case "kirmizi":
      return Colors.red;
    case "mavi":
      return Colors.blue;
    case "sari":
      return Colors.orange;
    case "siyah":
      return Colors.black;
    case "gri":
      return Colors.grey;
    case "turkuaz":
      return const Color(0xFF40E0D0);
    default:
      return Colors.transparent;
  }
}

class RozetController extends GetxController {
  static RozetController ensure(
    String userID, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      RozetController(userID),
      tag: tag,
      permanent: permanent,
    );
  }

  static RozetController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<RozetController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<RozetController>(tag: tag);
  }

  final String userID;
  RozetController(this.userID);
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

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
      final summary = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
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

class RozetContent extends StatefulWidget {
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

  @override
  State<RozetContent> createState() => _RozetContentState();
}

class _RozetContentState extends State<RozetContent> {
  late final String _controllerTag;
  late final RozetController controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'rozet_${widget.userID}_${identityHashCode(this)}';
    _ownsController = RozetController.maybeFind(tag: _controllerTag) == null;
    controller = RozetController.ensure(widget.userID, tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          RozetController.maybeFind(tag: _controllerTag),
          controller,
        )) {
      Get.delete<RozetController>(tag: _controllerTag);
    }
    super.dispose();
  }

  Widget _badge(Color color) {
    return Transform.translate(
      offset: const Offset(0, -1),
      child: Padding(
        padding: EdgeInsets.only(left: widget.leftSpacing),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.size - 7,
              height: widget.size - 7,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            Icon(
              CupertinoIcons.checkmark_seal_fill,
              color: color,
              size: widget.size,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final knownRozet = (widget.rozetValue ?? '').trim();
    if (knownRozet.isNotEmpty) {
      final mapped = mapRozetToColor(knownRozet);
      return mapped == Colors.transparent
          ? const SizedBox.shrink()
          : _badge(mapped);
    }

    if (widget.userID.isEmpty) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final color = controller.color.value;
      return color == Colors.transparent
          ? const SizedBox.shrink()
          : _badge(color);
    });
  }
}
