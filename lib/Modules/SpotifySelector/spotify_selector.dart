import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Models/music_model.dart';
import 'package:turqappv2/Modules/SpotifySelector/spotify_selector_controller.dart';

class SpotifySelector extends StatefulWidget {
  const SpotifySelector({super.key});

  @override
  State<SpotifySelector> createState() => _SpotifySelectorState();
}

class _SpotifySelectorState extends State<SpotifySelector> {
  late final SpotifySelectorController controller;
  late final String _controllerTag;

  static const List<String> _tabs = <String>[
    'spotify.tab.for_you',
    'spotify.tab.popular',
    'spotify.tab.all',
    'common.saved',
  ];

  @override
  void initState() {
    super.initState();
    _controllerTag = 'spotify_selector_${identityHashCode(this)}';
    controller = SpotifySelectorController.ensure(tag: _controllerTag);
  }

  @override
  void dispose() {
    final existing = SpotifySelectorController.maybeFind(tag: _controllerTag);
    if (identical(existing, controller)) {
      Get.delete<SpotifySelectorController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'spotify.title'.tr),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: _searchBar(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: _tabBar(),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tracks = controller.currentTabTracks();
                if (tracks.isEmpty) {
                  return Center(
                    child: Text(
                      'spotify.empty'.tr,
                      style: TextStyle(
                        color: Color(0xFF7A828C),
                        fontSize: 14,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  controller: controller.scrollController,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 120),
                  itemBuilder: (context, index) => _trackTile(tracks[index]),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: tracks.length,
                );
              }),
            ),
            Obx(() {
              final currentTrack = controller.currentTrack;
              if (currentTrack == null) return const SizedBox.shrink();
              return SafeArea(
                top: false,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      _cover(currentTrack, size: 46, radius: 12),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentTrack.title.isNotEmpty
                                  ? currentTrack.title
                                  : 'spotify.untitled_track'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'MontserratSemiBold',
                              ),
                            ),
                            if (currentTrack.hasDisplayArtist)
                              Text(
                                currentTrack.displayArtist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontFamily: 'MontserratMedium',
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => controller.playMusic(currentTrack),
                        icon: const Icon(
                          CupertinoIcons.pause_solid,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.back(result: currentTrack),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color(0xFF205FFF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.arrow_right,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.search,
            color: Color(0xFF7B8794),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'story_music.search_hint'.tr,
                hintStyle: const TextStyle(
                  color: Color(0xFF9AA5B1),
                  fontSize: 14,
                  fontFamily: 'MontserratMedium',
                ),
              ),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: 'MontserratMedium',
              ),
            ),
          ),
          Obx(() {
            if (controller.query.value.isEmpty) {
              return const SizedBox.shrink();
            }
            return GestureDetector(
              onTap: controller.searchController.clear,
              child: const Icon(
                CupertinoIcons.clear_circled_solid,
                color: Color(0xFF8A94A3),
                size: 18,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Obx(
      () => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final selected = controller.selectedTab.value == index;
            return Padding(
              padding:
                  EdgeInsets.only(right: index == _tabs.length - 1 ? 0 : 8),
              child: GestureDetector(
                onTap: () => controller.selectedTab.value = index,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF111827)
                        : const Color(0xFFF3F5F7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _tabs[index].tr,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF5B6572),
                      fontSize: 12,
                      fontFamily:
                          selected ? 'MontserratSemiBold' : 'MontserratMedium',
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

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
