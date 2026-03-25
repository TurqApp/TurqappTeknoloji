part of 'post_content_controller.dart';

class _PostContentControllerSupportPart {
  final PostContentController _controller;

  const _PostContentControllerSupportPart(this._controller);

  bool get canSendAdminPush {
    return _controller._canSendAdminPush ||
        AdminAccessService.isKnownAdminSync();
  }

  ({String title, String body}) buildPostPushCopy() {
    final senderName = _controller.fullName.value.trim().isNotEmpty
        ? _controller.fullName.value.trim()
        : _controller.nickname.value.trim();
    final safeSender = senderName.isNotEmpty ? senderName : 'app.name'.tr;
    final hasVideo = _controller.model.video.trim().isNotEmpty;
    final hasImage = _controller.model.img.isNotEmpty;
    final text = _controller.model.metin.trim();

    final preview =
        text.length > 90 ? '${text.substring(0, 90).trim()}...' : text;
    final title = '$safeSender yeni bir gonderi paylasti';
    final body = preview.isNotEmpty
        ? preview
        : hasVideo
            ? 'Yeni video gonderisi'
            : hasImage
                ? 'Yeni fotograf gonderisi'
                : 'Yeni gonderi paylasti';
    return (title: title, body: body);
  }

  String? pushPreviewImageUrl() {
    if (_controller.model.img.isNotEmpty) {
      final firstImage = _controller.model.img.first.trim();
      if (firstImage.isNotEmpty) return firstImage;
    }
    final thumbnail = _controller.model.thumbnail.trim();
    if (thumbnail.isNotEmpty) return thumbnail;
    return null;
  }

  String get reshareTargetPostId {
    final originalPostId = _controller.model.originalPostID.trim();
    if (originalPostId.isNotEmpty && _controller.model.quotedPost != true) {
      return originalPostId;
    }
    return _controller.model.docID;
  }
}
