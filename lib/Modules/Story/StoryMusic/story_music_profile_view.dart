import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/Services/story_music_library_service.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/music_model.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/story_maker_controller.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/story_model.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_user_model.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/story_viewer.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class StoryMusicProfileView extends StatefulWidget {
  final String musicId;

  const StoryMusicProfileView({
    super.key,
    required this.musicId,
  });

  @override
  State<StoryMusicProfileView> createState() => _StoryMusicProfileViewState();
}

class _StoryMusicProfileViewState extends State<StoryMusicProfileView> {
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final StoryRepository _storyRepository = StoryRepository.ensure();
  bool _isLoading = true;
  MusicModel? _track;
  List<_MusicStoryEntry> _entries = const [];

  String get _currentUid {
    final serviceUid = CurrentUserService.instance.userId.trim();
    if (serviceUid.isNotEmpty) return serviceUid;
    return FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final service = StoryMusicLibraryService.instance;
    final track = await service.fetchTrackById(widget.musicId, preferCache: true);
    final links = await service.fetchStoryLinks(widget.musicId, limit: 60);

    final storyIds = <String>{};
    for (final link in links) {
      final id = (link.data()['storyId'] ?? link.id).toString().trim();
      if (id.isNotEmpty) {
        storyIds.add(id);
      }
    }

    final storyDocsById = <String, StoryModel>{};
    if (storyIds.isNotEmpty) {
      storyDocsById.addAll(await _storyRepository.fetchStoriesByIds(storyIds.toList(growable: false)));
    }

    if (storyDocsById.isEmpty) {
      try {
        final fallbackStories = await _storyRepository.fetchActiveStoriesByMusicId(
          widget.musicId,
          limit: 60,
        );
        for (final story in fallbackStories) {
          storyDocsById[story.id] = story;
        }
      } catch (_) {}
    }

    final activeStories = <StoryModel>[];
    final orderedIds = <String>[
      ...links
          .map((link) => (link.data()['storyId'] ?? link.id).toString().trim())
          .where((id) => id.isNotEmpty),
      ...storyDocsById.keys,
    ];
    for (final id in orderedIds.toSet()) {
      final story = storyDocsById[id];
      if (story == null) continue;
      if (DateTime.now().difference(story.createdAt).inHours >= 24) continue;
      activeStories.add(story);
    }

    final userIds = activeStories
        .map((story) => story.userId.trim())
        .where((uid) => uid.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final userDataById = await _userSummaryResolver.resolveMany(userIds);
    if (userIds.isNotEmpty) {
    }

    final currentUid = _currentUid;
    final entries = activeStories.map((story) {
      final userData = userDataById[story.userId];
      final nickname = _resolveNickname(userData, story.userId == currentUid);
      final fullName = _resolveFullName(userData);
      final avatarUrl = _resolveAvatar(userData, story.userId == currentUid);
      final user = StoryUserModel(
        nickname: nickname,
        avatarUrl: avatarUrl,
        fullName: fullName,
        userID: story.userId,
        stories: [story],
      );
      return _MusicStoryEntry(story: story, user: user);
    }).toList(growable: false)
      ..sort((a, b) => b.story.createdAt.compareTo(a.story.createdAt));

    if (!mounted) return;
    setState(() {
      _track = track;
      _entries = entries;
      _isLoading = false;
    });
  }

  String _resolveNickname(UserSummary? data, bool isCurrentUser) {
    if (isCurrentUser) {
      final current = CurrentUserService.instance.fullName.trim();
      if (current.isNotEmpty) return current;
    }
    final nickname = data?.nickname.trim() ?? '';
    if (nickname.isNotEmpty) return nickname;
    final displayName = data?.displayName.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;
    return 'story.placeholder_nickname'.tr;
  }

  String _resolveFullName(UserSummary? data) {
    return data?.displayName.trim() ?? '';
  }

  String _resolveAvatar(UserSummary? data, bool isCurrentUser) {
    if (isCurrentUser) {
      final currentPhoto = CurrentUserService.instance.avatarUrl.trim();
      if (currentPhoto.isNotEmpty) return currentPhoto;
    }
    return data?.avatarUrl ?? '';
  }

  StoryElement? _resolvePreviewElement(StoryModel story) {
    for (final element in story.elements) {
      if (element.type == StoryElementType.image ||
          element.type == StoryElementType.gif ||
          element.type == StoryElementType.video) {
        return element;
      }
    }
    return story.elements.isNotEmpty ? story.elements.first : null;
  }

  Future<void> _openStory(_MusicStoryEntry entry) async {
    final startedUser = StoryUserModel(
      nickname: entry.user.nickname,
      avatarUrl: entry.user.avatarUrl,
      fullName: entry.user.fullName,
      userID: entry.user.userID,
      stories: [entry.story],
    );
    await Get.to(
      () => StoryViewer(
        startedUser: startedUser,
        storyOwnerUsers: [startedUser],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                                  (context, index) {
                                    final entry = _entries[index];
                                    final preview =
                                        _resolvePreviewElement(entry.story);
                                    final previewUrl =
                                        preview?.content.trim() ?? '';
                                    final isVideo =
                                        preview?.type == StoryElementType.video;
                                    return GestureDetector(
                                      onTap: () => _openStory(entry),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(
                                            color: const Color(0xFFE7EAF0),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                  top: Radius.circular(18),
                                                ),
                                                child: Stack(
                                                  fit: StackFit.expand,
                                                  children: [
                                                    if (previewUrl.isNotEmpty)
                                                      CachedNetworkImage(
                                                        imageUrl: previewUrl,
                                                        cacheManager:
                                                            TurqImageCacheManager
                                                                .instance,
                                                        fit: BoxFit.cover,
                                                        placeholder: (_, __) =>
                                                            Container(
                                                          color: const Color(
                                                              0xFFF2F4F7),
                                                        ),
                                                        errorWidget:
                                                            (_, __, ___) =>
                                                                Container(
                                                          color: const Color(
                                                              0xFFF2F4F7),
                                                          child: const Icon(
                                                            CupertinoIcons
                                                                .photo,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      )
                                                    else
                                                      Container(
                                                        color: const Color(
                                                            0xFFF2F4F7),
                                                        child: const Icon(
                                                          CupertinoIcons.music_note_2,
                                                          color: Colors.grey,
                                                          size: 34,
                                                        ),
                                                      ),
                                                    if (isVideo)
                                                      const Center(
                                                        child: DecoratedBox(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Color(
                                                                0xAA000000),
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: Padding(
                                                            padding:
                                                                EdgeInsets.all(
                                                                    10),
                                                            child: Icon(
                                                              CupertinoIcons
                                                                  .play_fill,
                                                              color:
                                                                  Colors.white,
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
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      10, 10, 10, 10),
                                              child: Row(
                                                children: [
                                                  ClipOval(
                                                    child: SizedBox(
                                                      width: 28,
                                                      height: 28,
                                                      child: entry
                                                              .user.avatarUrl
                                                              .trim()
                                                              .isNotEmpty
                                                          ? CachedNetworkImage(
                                                              imageUrl: entry
                                                                  .user.avatarUrl,
                                                              cacheManager:
                                                                  TurqImageCacheManager
                                                                      .instance,
                                                              fit: BoxFit.cover,
                                                              placeholder: (_,
                                                                      __) =>
                                                                  Container(
                                                                color: const Color(
                                                                    0xFFF2F4F7),
                                                              ),
                                                              errorWidget:
                                                                  (_, __, ___) =>
                                                                      Container(
                                                                color: const Color(
                                                                    0xFFF2F4F7),
                                                              ),
                                                            )
                                                          : Container(
                                                              color: const Color(
                                                                  0xFFF2F4F7),
                                                            ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          entry.user.nickname,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.black,
                                                            fontSize: 13,
                                                            fontFamily:
                                                                'MontserratSemiBold',
                                                          ),
                                                        ),
                                                        Text(
                                                          _timeAgo(entry.story
                                                              .createdAt),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                            color: Color(
                                                                0xFF7B8794),
                                                            fontSize: 11,
                                                            fontFamily:
                                                                'MontserratMedium',
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
                                  },
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

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'common.now'.tr;
    if (diff.inMinutes < 60) {
      return 'story_music.minutes_ago'.trParams(
        {'count': '${diff.inMinutes}'},
      );
    }
    if (diff.inHours < 24) {
      return 'story_music.hours_ago'.trParams(
        {'count': '${diff.inHours}'},
      );
    }
    return 'story_music.days_ago'.trParams(
      {'count': '${diff.inDays}'},
    );
  }
}

class _MusicStoryEntry {
  final StoryModel story;
  final StoryUserModel user;

  const _MusicStoryEntry({
    required this.story,
    required this.user,
  });
}
