part of 'spotify_selector.dart';

extension _SpotifySelectorShellContentPart on _SpotifySelectorState {
  Widget _buildPageContent(BuildContext context) {
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
                      style: const TextStyle(
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
            _buildCurrentTrackBar(),
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
          children: List.generate(_SpotifySelectorState._tabs.length, (index) {
            final selected = controller.selectedTab.value == index;
            return Padding(
              padding: EdgeInsets.only(
                right: index == _SpotifySelectorState._tabs.length - 1 ? 0 : 8,
              ),
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
                    _SpotifySelectorState._tabs[index].tr,
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

  Widget _buildCurrentTrackBar() {
    return Obx(() {
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
    });
  }
}
