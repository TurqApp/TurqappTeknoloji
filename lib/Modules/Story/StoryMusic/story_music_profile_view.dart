import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/Services/story_music_library_service.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Models/music_model.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/story_maker_controller.dart';
import 'package:turqappv2/Modules/Story/StoryMaker/story_model.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_user_model.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/story_viewer.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'story_music_profile_view_story_part.dart';
part 'story_music_profile_view_content_part.dart';

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

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final service = StoryMusicLibraryService.instance;
    final track =
        await service.fetchTrackById(widget.musicId, preferCache: true);
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
      storyDocsById.addAll(await _storyRepository
          .fetchStoriesByIds(storyIds.toList(growable: false)));
    }

    if (storyDocsById.isEmpty) {
      try {
        final fallbackStories =
            await _storyRepository.fetchActiveStoriesByMusicId(
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
    if (userIds.isNotEmpty) {}

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

  @override
  Widget build(BuildContext context) => _buildPage(context);
}

class _MusicStoryEntry {
  final StoryModel story;
  final StoryUserModel user;

  const _MusicStoryEntry({
    required this.story,
    required this.user,
  });
}
