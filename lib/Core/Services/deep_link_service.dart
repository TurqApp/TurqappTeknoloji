import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/redirection_link.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/FloodListing/flood_listing.dart';
import 'package:turqappv2/Modules/Social/PhotoShorts/photo_shorts.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/story_model.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_user_model.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/story_viewer.dart';
import 'package:turqappv2/Modules/Short/single_short_view.dart';

class DeepLinkService extends GetxService {
  final AppLinks _appLinks = AppLinks();
  final ShortLinkService _shortLinkService = ShortLinkService();
  StreamSubscription<Uri>? _subscription;
  bool _started = false;
  bool _handling = false;

  void start() {
    if (_started) return;
    _started = true;

    _appLinks.getInitialLink().then((initial) {
      if (initial != null) {
        unawaited(_handle(initial));
      }
    }).catchError((_) {});

    _subscription = _appLinks.uriLinkStream.listen(
      (uri) => unawaited(_handle(uri)),
      onError: (_) {},
    );
  }

  Future<void> _handle(Uri uri) async {
    if (_handling) return;
    final parsed = _parse(uri);
    if (parsed == null) return;

    _handling = true;
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        return;
      }

      final resolved = await _shortLinkService.resolve(
        type: parsed.type,
        id: parsed.id,
      );

      final data = Map<String, dynamic>.from(
        resolved['data'] as Map? ?? const {},
      );
      final entityId = (data['entityId'] ?? '').toString().trim();
      if (entityId.isEmpty) {
        final handled = await _tryDirectFallback(parsed);
        if (!handled) {
          AppSnackbar('Bilgi', 'Link çözülemedi.');
        }
        return;
      }

      switch (parsed.type) {
        case 'post':
          await _openPost(entityId);
          return;
        case 'story':
          await _openStory(entityId);
          return;
        case 'user':
          Get.to(() => SocialProfile(userID: entityId));
          return;
      }
    } catch (_) {
      final handled = await _tryDirectFallback(parsed);
      if (!handled) {
        AppSnackbar('Bilgi', 'Link açılamadı.');
      }
    } finally {
      _handling = false;
    }
  }

  Future<bool> _tryDirectFallback(_ParsedDeepLink parsed) async {
    final rawId = parsed.id.trim();
    if (rawId.isEmpty) return false;
    try {
      switch (parsed.type) {
        case 'post':
          await _openPost(rawId);
          return true;
        case 'story':
          await _openStory(rawId);
          return true;
        case 'user':
          Get.to(() => SocialProfile(userID: rawId));
          return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  _ParsedDeepLink? _parse(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments.where((e) => e.isNotEmpty).toList();

    if (scheme == 'http' || scheme == 'https') {
      if (!(host == 'turqapp.com' ||
          host == 'www.turqapp.com' ||
          host == 'go.turqapp.com')) {
        return null;
      }
      if (segments.length < 2) return null;
      final type = _normalizeType(segments[0]);
      if (type == null) return null;
      final id = _normalizeId(segments[1]);
      if (id.isEmpty) return null;
      return _ParsedDeepLink(type: type, id: id);
    }

    if (scheme == 'turqapp') {
      if (host.isNotEmpty) {
        final mappedHostType = _normalizeType(host);
        if (mappedHostType != null && segments.isNotEmpty) {
          final id = _normalizeId(segments.first);
          if (id.isEmpty) return null;
          return _ParsedDeepLink(type: mappedHostType, id: id);
        }
      }
      if (segments.length >= 2) {
        final type = _normalizeType(segments[0]);
        if (type != null) {
          final id = _normalizeId(segments[1]);
          if (id.isEmpty) return null;
          return _ParsedDeepLink(type: type, id: id);
        }
      }
    }

    return null;
  }

  String? _normalizeType(String raw) {
    final value = raw.toLowerCase();
    if (value == 'p' || value == 'post') return 'post';
    if (value == 's' || value == 'story') return 'story';
    if (value == 'u' || value == 'user' || value == 'profile') return 'user';
    return null;
  }

  String _normalizeId(String raw) {
    var id = raw.trim();
    // Mesaj içinde yazılırken sona gelen noktalama/boş karakterleri temizle.
    id = id.replaceAll(RegExp(r'^[^A-Za-z0-9_-]+'), '');
    id = id.replaceAll(RegExp(r'[^A-Za-z0-9_-]+$'), '');
    return id;
  }

  Future<void> _openPost(String postId) async {
    final doc =
        await FirebaseFirestore.instance.collection('Posts').doc(postId).get();
    if (!doc.exists) {
      AppSnackbar('Bilgi', 'Gönderi bulunamadı.');
      return;
    }

    final model = PostsModel.fromFirestore(doc);
    if (model.deletedPost) {
      AppSnackbar('Bilgi', 'Gönderi kaldırılmış.');
      return;
    }

    if (model.video.trim().isNotEmpty) {
      await Get.to(() => SingleShortView(
            startModel: model,
            startList: [model],
          ));
      return;
    }

    if (model.flood == false && model.floodCount > 1) {
      await Get.to(() => FloodListing(mainModel: model));
      return;
    }

    if (model.img.isNotEmpty) {
      await Get.to(() => PhotoShorts(
            fetchedList: [model],
            startModel: model,
          ));
      return;
    }

    // İçerik tipi çözülemezse web fallback
    await RedirectionLink().goToLink('https://turqapp.com/p/$postId');
  }

  Future<void> _openStory(String storyId) async {
    final storyRef =
        FirebaseFirestore.instance.collection('stories').doc(storyId);
    final storyDoc = await storyRef.get();
    if (!storyDoc.exists) {
      AppSnackbar('Bilgi', 'Hikaye bulunamadı.');
      return;
    }

    final storyData = storyDoc.data() as Map<String, dynamic>;
    if ((storyData['deleted'] ?? false) == true) {
      AppSnackbar('Bilgi', 'Hikaye süresi dolmuş veya silinmiş.');
      return;
    }

    final userId = (storyData['userId'] ?? '').toString().trim();
    if (userId.isEmpty) {
      AppSnackbar('Bilgi', 'Hikaye sahibi bulunamadı.');
      return;
    }

    final userSnap =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (!userSnap.exists) {
      AppSnackbar('Bilgi', 'Hikaye sahibi bulunamadı.');
      return;
    }

    final storiesSnap = await FirebaseFirestore.instance
        .collection('stories')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    final stories = storiesSnap.docs
        .where((d) => (d.data()['deleted'] ?? false) != true)
        .map(StoryModel.fromDoc)
        .toList();

    if (stories.isEmpty) {
      AppSnackbar('Bilgi', 'Hikaye bulunamadı.');
      return;
    }

    final index = stories.indexWhere((e) => e.id == storyId);
    if (index > 0) {
      final target = stories.removeAt(index);
      stories.insert(0, target);
    }

    final userData = userSnap.data() as Map<String, dynamic>;
    final user = StoryUserModel(
      nickname: (userData['nickname'] ?? '').toString(),
      pfImage: (userData['pfImage'] ?? '').toString(),
      fullName:
          '${(userData['firstName'] ?? '').toString()} ${(userData['lastName'] ?? '').toString()}'
              .trim(),
      userID: userId,
      stories: stories,
    );

    await Get.to(() => StoryViewer(
          startedUser: user,
          storyOwnerUsers: [user],
        ));
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _subscription = null;
    _started = false;
    super.onClose();
  }
}

class _ParsedDeepLink {
  final String type;
  final String id;

  _ParsedDeepLink({required this.type, required this.id});
}
