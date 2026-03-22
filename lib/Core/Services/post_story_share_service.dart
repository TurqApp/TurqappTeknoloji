import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/cdn_url_builder.dart';
import 'package:turqappv2/Core/Utils/url_utils.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/story_maker.dart';
import 'package:turqappv2/Services/reshare_helper.dart';

import '../app_snackbar.dart';

class PostStoryShareSeed {
  const PostStoryShareSeed({
    required this.mediaUrl,
    required this.isVideo,
    required this.aspectRatio,
    required this.sourceUserId,
    required this.sourceDisplayName,
  });

  final String mediaUrl;
  final bool isVideo;
  final double aspectRatio;
  final String sourceUserId;
  final String sourceDisplayName;
}

class PostStoryShareService {
  static Future<void> openStoryMakerForPost(PostsModel model) async {
    final seed = await buildSeed(model);
    if (seed == null) {
      AppSnackbar('common.error'.tr, 'post_story_share.media_missing'.tr);
      return;
    }

    await Get.to(
      () => StoryMaker(
        initialMediaUrl: seed.mediaUrl,
        initialMediaIsVideo: seed.isVideo,
        initialMediaAspectRatio: seed.aspectRatio,
        initialSourceUserId: seed.sourceUserId,
        initialSourceDisplayName: seed.sourceDisplayName,
      ),
    );
  }

  static Future<PostStoryShareSeed?> buildSeed(PostsModel model) async {
    final media = _resolveMedia(model);
    if (media == null) return null;

    final sourceUserId = _resolveSourceUserId(model);
    final sourceDisplayName =
        await _resolveSourceDisplayName(model, sourceUserId);

    return PostStoryShareSeed(
      mediaUrl: media.url,
      isVideo: media.isVideo,
      aspectRatio: media.aspectRatio,
      sourceUserId: sourceUserId,
      sourceDisplayName: sourceDisplayName,
    );
  }

  static String resolveOriginalUserId(PostsModel model) {
    final original = model.originalUserID.trim();
    if (original.isNotEmpty) return original;
    return model.userID.trim();
  }

  static String resolveOriginalPostId(PostsModel model) {
    final original = model.originalPostID.trim();
    if (original.isNotEmpty) return original;
    return model.docID.trim();
  }

  static String _resolveSourceUserId(PostsModel model) {
    if (model.quotedPost && model.quotedSourceUserID.trim().isNotEmpty) {
      return model.quotedSourceUserID.trim();
    }
    if (model.originalUserID.trim().isNotEmpty) {
      return model.originalUserID.trim();
    }
    return model.userID.trim();
  }

  static Future<String> _resolveSourceDisplayName(
    PostsModel model,
    String userId,
  ) async {
    if (userId == model.userID.trim() && model.authorNickname.trim().isNotEmpty) {
      return model.authorNickname.trim();
    }

    final nickname = await ReshareHelper.getUserNickname(userId);
    if (!ReshareHelper.isUnknownUserLabel(nickname)) {
      return nickname.trim();
    }

    if (model.quotedPost && model.quotedSourceDisplayName.trim().isNotEmpty) {
      return model.quotedSourceDisplayName.trim();
    }

    final displayName = await ReshareHelper.getUserDisplayName(userId);
    if (!ReshareHelper.isUnknownUserLabel(displayName)) {
      return displayName.trim();
    }

    return model.authorNickname.trim();
  }

  static ({String url, bool isVideo, double aspectRatio})? _resolveMedia(
    PostsModel model,
  ) {
    final playbackUrl = model.playbackUrl.trim();
    if (playbackUrl.isNotEmpty) {
      return (
        url: CdnUrlBuilder.toCdnUrl(playbackUrl),
        isVideo: true,
        aspectRatio: _normalizeAspectRatio(model.aspectRatio),
      );
    }

    final imageUrl = model.img
        .map((e) => e.trim())
        .firstWhere((e) => e.isNotEmpty, orElse: () => '');
    if (imageUrl.isNotEmpty) {
      return (
        url: CdnUrlBuilder.toCdnUrl(imageUrl),
        isVideo: false,
        aspectRatio: _normalizeAspectRatio(model.aspectRatio),
      );
    }

    final rawVideo = model.video.trim();
    if (rawVideo.isNotEmpty && !isHlsPlaylistUrl(rawVideo)) {
      return (
        url: CdnUrlBuilder.toCdnUrl(rawVideo),
        isVideo: true,
        aspectRatio: _normalizeAspectRatio(model.aspectRatio),
      );
    }

    if (model.docID.trim().isNotEmpty &&
        (model.hlsMasterUrl.trim().isNotEmpty ||
            rawVideo.isNotEmpty ||
            model.thumbnail.trim().isNotEmpty)) {
      return (
        url: CdnUrlBuilder.buildVideoUrl(model.docID.trim()),
        isVideo: true,
        aspectRatio: _normalizeAspectRatio(model.aspectRatio),
      );
    }

    final thumbnail = model.thumbnail.trim();
    if (thumbnail.isNotEmpty) {
      return (
        url: CdnUrlBuilder.toCdnUrl(thumbnail),
        isVideo: false,
        aspectRatio: _normalizeAspectRatio(model.aspectRatio),
      );
    }

    return null;
  }

  static double _normalizeAspectRatio(num raw) {
    final value = raw.toDouble();
    if (value.isNaN || !value.isFinite || value <= 0) {
      return 9 / 16;
    }
    return value.clamp(0.35, 3.0);
  }
}
