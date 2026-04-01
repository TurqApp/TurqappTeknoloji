part of 'message_content.dart';

extension MessageContentBodyParts on MessageContent {
  Widget locationBar() {
    final mediaSize = _mediaBubbleSize();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: model.userID == _currentUserId
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: controller.showMapsSheet,
            onTapDown: _captureTapDown,
            onLongPressStart: _openMenuFromLongPressStart,
            onDoubleTap: () {
              controller.likeImage();
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  child: SizedBox(
                    width: mediaSize,
                    height: mediaSize,
                    child: AbsorbPointer(
                      // Etkileşimi tamamen engeller
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                              model.lat.toDouble(), model.long.toDouble()),
                          zoom: 14,
                        ),
                        zoomControlsEnabled:
                            false, // Sağ alt zoom butonlarını kaldırır
                        myLocationButtonEnabled:
                            false, // Sağ alt konum butonunu kaldırır
                        scrollGesturesEnabled: false, // Sürükleme kapalı
                        rotateGesturesEnabled: false,
                        tiltGesturesEnabled: false,
                        zoomGesturesEnabled: false,
                        mapToolbarEnabled:
                            false, // Sağ üstteki rota ve benzeri araçları kaldırır
                      ),
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.location_solid,
                  color: Colors.red,
                  size: 30,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget contactInfoBar() {
    return Row(
      mainAxisAlignment: model.userID == _currentUserId
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: controller.addContact,
          onTapDown: _captureTapDown,
          onLongPressStart: _openMenuFromLongPressStart,
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(12)),
                border: Border.all(color: Colors.blueAccent)),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(50),
                        shape: BoxShape.circle),
                    child: Icon(
                      CupertinoIcons.person_fill,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(
                    width: 12,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.kisiAdSoyad,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "Montserrat",
                        ),
                      ),
                      SizedBox(
                        height: 3,
                      ),
                      TextButton(
                        onPressed: () {
                          controller.addContact();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero, // İç boşluk yok
                          minimumSize: Size(0, 0), // Minimum boyut 0
                          tapTargetSize: MaterialTapTargetSize
                              .shrinkWrap, // Tıklama alanını küçült
                        ),
                        child: Text(
                          "Rehbere Ekle",
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 13,
                            fontFamily: "Montserrat",
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget videoBubble() {
    final mediaSize = _mediaBubbleSize();
    return Row(
      mainAxisAlignment: model.userID == _currentUserId
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openVideoPreview,
          onTapDown: _captureTapDown,
          onLongPressStart: _openMenuFromLongPressStart,
          child: Container(
            width: mediaSize,
            height: mediaSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (model.videoThumbnail.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: model.videoThumbnail,
                      cacheManager: TurqImageCacheManager.instance,
                      fit: BoxFit.cover,
                      width: mediaSize,
                      height: mediaSize,
                    )
                  else
                    Container(color: Colors.grey[800]),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                    child: const Icon(
                      CupertinoIcons.play_fill,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: _mediaTimeOverlay(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget audioBubble() {
    return Row(
      mainAxisAlignment: model.userID == _currentUserId
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _captureTapDown,
          onLongPressStart: _openMenuFromLongPressStart,
          child: _AudioPlayerWidget(
            audioUrl: model.sesliMesaj,
            durationMs: model.audioDurationMs,
            isMine: model.userID == _currentUserId,
          ),
        ),
      ],
    );
  }

  Widget timeBar() {
    if (model.video.isNotEmpty ||
        model.imgs.isNotEmpty ||
        model.postID.isNotEmpty ||
        model.metin.isNotEmpty ||
        model.isUnsent) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        if (model.reactions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _reactionBadges(),
          ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Row(
            mainAxisAlignment: model.userID == _currentUserId
                ? MainAxisAlignment.end
                : MainAxisAlignment.end,
            children: [
              Text(
                _formatHourMinute(model.timeStamp),
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 10,
                  fontFamily: "Montserrat",
                ),
              ),
              if (model.userID == _currentUserId) ...[
                const SizedBox(width: 3),
                _buildStatusTicks(
                  readColor: const Color(0xFF53BDEB),
                  defaultColor: Colors.black54,
                  size: 12,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatHourMinute(num ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts.toInt());
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Widget _mediaTimeOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (model.userID == _currentUserId) ...[
            _buildStatusTicks(),
            const SizedBox(width: 4),
          ],
          Text(
            _formatHourMinute(model.timeStamp),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontFamily: "Montserrat",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTicks({
    Color? readColor,
    Color? defaultColor,
    double size = 10,
  }) {
    final status = model.status;
    final bool isRead = status == "read" || (status.isEmpty && model.isRead);
    final Color tickColor =
        isRead ? const Color(0xFF53BDEB) : (defaultColor ?? Colors.black38);

    return Icon(
      CupertinoIcons.checkmark,
      color: tickColor,
      size: size,
    );
  }

  Widget _reactionBadges() {
    final entries = model.reactions.entries
        .where((e) => e.value.isNotEmpty)
        .take(5)
        .toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: entries
          .map(
            (e) => Container(
              margin: const EdgeInsets.only(right: 5),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Text(
                "${e.key} ${e.value.length}",
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontFamily: "Montserrat",
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
