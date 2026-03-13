part of 'message_content.dart';

class _ReplyPostFutureCacheEntry {
  final Future<NotifyPostLookup> future;
  final DateTime createdAt;

  const _ReplyPostFutureCacheEntry({
    required this.future,
    required this.createdAt,
  });
}

final Map<String, _ReplyPostFutureCacheEntry> _replyPostFutureCache = {};
const Duration _replyPostFutureTtl = Duration(seconds: 30);

extension MessageContentReplyParts on MessageContent {
  Future<NotifyPostLookup> _getReplyPostFuture(String target) {
    final key = target.trim();
    final now = DateTime.now();
    final cached = _replyPostFutureCache[key];
    if (cached != null &&
        now.difference(cached.createdAt) < _replyPostFutureTtl) {
      return cached.future;
    }

    final future = NotifyLookupRepository.ensure().getPostLookup(key);
    _replyPostFutureCache[key] =
        _ReplyPostFutureCacheEntry(future: future, createdAt: now);

    if (_replyPostFutureCache.length > 400) {
      _replyPostFutureCache.clear();
    }
    return future;
  }

  Widget _buildMessageMetaRow(bool isMine) {
    final metaColor = isMine ? const Color(0xFF6D9E6B) : Colors.black38;
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (model.isStarred) ...[
            Icon(CupertinoIcons.star_fill, color: Colors.amber, size: 10),
            const SizedBox(width: 3),
          ],
          if (model.isEdited) ...[
            Text("düzenlendi",
                style: TextStyle(
                    color: metaColor, fontSize: 10, fontFamily: "Montserrat")),
            const SizedBox(width: 3),
          ],
          Text(
            _formatHourMinute(model.timeStamp),
            style: TextStyle(
              color: metaColor,
              fontSize: 11,
              fontFamily: "Montserrat",
            ),
          ),
          if (isMine) ...[
            const SizedBox(width: 3),
            _buildStatusTicks(
              readColor: const Color(0xFF53BDEB),
              defaultColor: const Color(0xFF6D9E6B),
              size: 14,
            ),
          ],
        ],
      ),
    );
  }

  String _replySenderLabel() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (model.replySenderId.trim().isNotEmpty &&
        model.replySenderId.trim() == currentUid) {
      return "Siz";
    }
    final peer = chatController.nickname.value.trim();
    return peer.isEmpty ? "TurqApp" : peer;
  }

  String _replyPreviewText() {
    final text = model.replyText.trim();
    if (text.isNotEmpty) return text;
    switch (model.replyType.trim().toLowerCase()) {
      case "media":
        return "Fotoğraf";
      case "video":
        return "Video";
      case "audio":
        return "Ses";
      case "location":
        return "Konum";
      case "post":
        return "Gönderi";
      default:
        return "";
    }
  }

  Widget _buildReplyCard() {
    final target = model.replyMessageId.trim();
    final type = model.replyType.trim().toLowerCase();
    final preview = _replyPreviewText();
    final canOpenMedia =
        (type == "media" || type == "video") && target.isNotEmpty;
    final hasTrailingPreview = target.isNotEmpty;
    return GestureDetector(
      onTap: canOpenMedia ? _openReplyTargetMedia : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1A73E8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _replySenderLabel(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0D5AA7),
                      fontSize: 13,
                      fontFamily: "Montserrat",
                    ),
                  ),
                  if (preview.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          fontFamily: "Montserrat",
                          height: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (hasTrailingPreview) ...[
              const SizedBox(width: 6),
              _buildReplyTrailing(type, target),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReplyTrailing(String type, String target) {
    final replied = _resolveReplyMessage(target);

    Widget iconTile(IconData icon) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: Colors.black54,
        ),
      );
    }

    if (type == "media") {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 40,
          height: 40,
          child: CachedNetworkImage(
            imageUrl: target,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => iconTile(CupertinoIcons.photo),
          ),
        ),
      );
    }
    if (type == "video") {
      final thumb = replied?.videoThumbnail.trim() ?? "";
      if (thumb.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: thumb,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      iconTile(CupertinoIcons.play_fill),
                ),
                Container(
                  color: Colors.black.withValues(alpha: 0.14),
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.play_fill,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return iconTile(CupertinoIcons.play_fill);
    }
    if (type == "location") {
      if (replied != null && (replied.lat != 0 || replied.long != 0)) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AbsorbPointer(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                          replied.lat.toDouble(), replied.long.toDouble()),
                      zoom: 13,
                    ),
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    scrollGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    zoomGesturesEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                ),
                const Center(
                  child: Icon(
                    CupertinoIcons.location_solid,
                    size: 13,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return iconTile(CupertinoIcons.location_solid);
    }
    if (type == "audio") {
      return iconTile(CupertinoIcons.mic_fill);
    }
    if (type == "post") {
      String replyThumbFromMessage() {
        if (replied == null) return "";
        if (replied.imgs.isNotEmpty && replied.imgs.first.trim().isNotEmpty) {
          return replied.imgs.first.trim();
        }
        if (replied.videoThumbnail.trim().isNotEmpty) {
          return replied.videoThumbnail.trim();
        }
        return "";
      }

      final fromMessage = replyThumbFromMessage();
      if (fromMessage.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 40,
            height: 40,
            child: CachedNetworkImage(
              imageUrl: fromMessage,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => iconTile(CupertinoIcons.doc),
            ),
          ),
        );
      }

      return FutureBuilder<NotifyPostLookup>(
        future: _getReplyPostFuture(target),
        builder: (context, snapshot) {
          final model = snapshot.data?.model;
          final imgList = model?.img ?? const <String>[];
          final thumb = (model?.thumbnail ?? '').trim();
          final fallbackImg = imgList.isNotEmpty ? imgList.first.trim() : "";
          final resolvedThumb = thumb.isNotEmpty ? thumb : fallbackImg;
          if (resolvedThumb.isNotEmpty) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 40,
                height: 40,
                child: CachedNetworkImage(
                  imageUrl: resolvedThumb,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => iconTile(CupertinoIcons.doc),
                ),
              ),
            );
          }
          return iconTile(CupertinoIcons.doc);
        },
      );
    }
    return const SizedBox.shrink();
  }

  MessageModel? _resolveReplyMessage(String target) {
    final t = target.trim();
    if (t.isEmpty) return null;
    for (final m in chatController.messages.reversed) {
      if (m.rawDocID == t || m.docID == t) return m;
      if (m.video.trim().isNotEmpty && m.video.trim() == t) return m;
      if (m.postID.trim().isNotEmpty && m.postID.trim() == t) return m;
      if (m.imgs.any((u) => u.trim() == t)) return m;
    }
    return null;
  }
}
