part of 'spotify_selector.dart';

extension _SpotifySelectorListPart on _SpotifySelectorState {
  Widget _trackTile(MusicModel track) {
    return Obx(() {
      final isPlaying = controller.currentPlayingUrl.value == track.audioUrl;
      final isSaved = controller.savedTrackIds.contains(track.docID);
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EBF0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D101828),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Get.back(result: track),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                children: [
                  _cover(track, size: 58, radius: 16),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title.isNotEmpty
                              ? track.title
                              : 'spotify.untitled_track'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: 'MontserratSemiBold',
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (track.hasDisplayArtist)
                          Text(
                            track.displayArtist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF667085),
                              fontSize: 13,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          'spotify.usage_summary'.trParams({
                            'storyCount': '${track.storyCount}',
                            'useCount': '${track.useCount}',
                          }),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF98A2B3),
                            fontSize: 11,
                            fontFamily: 'MontserratMedium',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => controller.playMusic(track),
                    icon: Icon(
                      isPlaying
                          ? CupertinoIcons.pause_circle_fill
                          : CupertinoIcons.play_circle_fill,
                      color: isPlaying
                          ? const Color(0xFF205FFF)
                          : const Color(0xFF111827),
                      size: 32,
                    ),
                    splashRadius: 22,
                  ),
                  IconButton(
                    onPressed: () => controller.toggleSaved(track),
                    icon: Icon(
                      isSaved
                          ? CupertinoIcons.bookmark_fill
                          : CupertinoIcons.bookmark,
                      color: isSaved
                          ? const Color(0xFFF4B400)
                          : const Color(0xFF667085),
                      size: 22,
                    ),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _cover(
    MusicModel track, {
    required double size,
    required double radius,
  }) {
    final coverUrl = track.coverUrl.trim();
    if (coverUrl.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4F7),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: const Icon(
          CupertinoIcons.music_note_2,
          color: Colors.black54,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: CachedNetworkImage(
          imageUrl: coverUrl,
          cacheManager: TurqImageCacheManager.instance,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: const Color(0xFFF1F4F7)),
          errorWidget: (_, __, ___) =>
              Container(color: const Color(0xFFF1F4F7)),
        ),
      ),
    );
  }
}
