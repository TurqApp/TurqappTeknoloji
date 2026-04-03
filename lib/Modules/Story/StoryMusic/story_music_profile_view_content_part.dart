part of 'story_music_profile_view.dart';

extension StoryMusicProfileViewContentPart on _StoryMusicProfileViewState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'story_music.title'.tr),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(child: _buildHeader()),
                          if (_entries.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Text(
                                  'story_music.no_active_stories'.tr,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                    fontFamily: 'MontserratMedium',
                                  ),
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
                              sliver: SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.78,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) =>
                                      _buildStoryCard(_entries[index]),
                                  childCount: _entries.length,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final track = _track;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: 86,
                height: 86,
                child: (track?.coverUrl.trim().isNotEmpty ?? false)
                    ? CachedNetworkImage(
                        imageUrl: track!.coverUrl,
                        cacheManager: TurqImageCacheManager.instance,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: const Color(0xFFE9EDF2),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFFE9EDF2),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFE9EDF2),
                        child: const Icon(
                          CupertinoIcons.music_note_2,
                          color: Colors.black54,
                          size: 36,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track?.title.trim().isNotEmpty == true
                        ? track!.title
                        : 'story_music.untitled'.tr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 19,
                      fontFamily: 'MontserratSemiBold',
                    ),
                  ),
                  if (track?.hasDisplayArtist == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      track!.displayArtist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6D7782),
                        fontSize: 14,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    'story_music.active_story_count'
                        .trParams({'count': '${_entries.length}'}),
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontFamily: 'MontserratSemiBold',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard(_MusicStoryEntry entry) {
    final preview = _resolvePreviewElement(entry.story);
    final previewUrl = preview?.content.trim() ?? '';
    final isVideo = preview?.type == StoryElementType.video;

    return GestureDetector(
      onTap: () => _openStory(entry),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE7EAF0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildPreviewMedia(previewUrl),
                    if (isVideo)
                      const Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0xAA000000),
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              CupertinoIcons.play_fill,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Row(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: _buildAvatar(entry.user.avatarUrl),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.user.nickname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontFamily: 'MontserratSemiBold',
                          ),
                        ),
                        Text(
                          _timeAgo(entry.story.createdAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF7B8794),
                            fontSize: 11,
                            fontFamily: 'MontserratMedium',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewMedia(String previewUrl) {
    if (previewUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: previewUrl,
        cacheManager: TurqImageCacheManager.instance,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: const Color(0xFFF2F4F7),
        ),
        errorWidget: (_, __, ___) => Container(
          color: const Color(0xFFF2F4F7),
          child: const Icon(
            CupertinoIcons.photo,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFFF2F4F7),
      child: const Icon(
        CupertinoIcons.music_note_2,
        color: Colors.grey,
        size: 34,
      ),
    );
  }

  Widget _buildAvatar(String avatarUrl) {
    return CachedUserAvatar(imageUrl: avatarUrl, radius: 14);
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'common.now'.tr;
    if (diff.inMinutes < 60) {
      return 'story_music.minutes_ago'.trParams({'count': '${diff.inMinutes}'});
    }
    if (diff.inHours < 24) {
      return 'story_music.hours_ago'.trParams({'count': '${diff.inHours}'});
    }
    return 'story_music.days_ago'.trParams({'count': '${diff.inDays}'});
  }
}
