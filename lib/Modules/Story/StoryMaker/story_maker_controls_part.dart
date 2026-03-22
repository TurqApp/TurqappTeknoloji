part of 'story_maker.dart';

extension _StoryMakerControlsPart on _StoryMakerState {
  Widget topBar() {
    return Container(
      padding: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppBackButton(
                icon: CupertinoIcons.arrow_left,
                iconColor: Colors.white,
                surfaceColor: Color(0x1FFFFFFF),
              ),
              Obx(
                () => IconButton(
                  onPressed: controller.canUndo.value ? controller.undo : null,
                  icon: Icon(
                    CupertinoIcons.arrow_uturn_left,
                    color:
                        controller.canUndo.value ? Colors.white : Colors.grey,
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 35,
                    minHeight: 35,
                  ),
                ),
              ),
              Obx(
                () => IconButton(
                  onPressed: controller.canRedo.value ? controller.redo : null,
                  icon: Icon(
                    CupertinoIcons.arrow_uturn_right,
                    color:
                        controller.canRedo.value ? Colors.white : Colors.grey,
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 35,
                    minHeight: 35,
                  ),
                ),
              ),
            ],
          ),
          Text(
            "story.create_title".tr,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: "MontserratMedium",
              color: Colors.white,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onLongPress: controller.onScheduleStoryPressed,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  onPressed: controller.onSaveStoryPressed,
                  child: Text(
                    "common.share".tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget bottomTools(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: TextButton(
              style: IconButtons.storyButtons,
              onPressed: controller.pickImage,
              child: const Icon(
                CupertinoIcons.photo,
                color: Colors.white,
                size: 25,
              ),
            ),
          ),
          Expanded(
            child: TextButton(
              style: IconButtons.storyButtons,
              onPressed: controller.pickVideo,
              child: const Icon(
                CupertinoIcons.play_circle,
                color: Colors.white,
                size: 25,
              ),
            ),
          ),
          Expanded(
            child: TextButton(
              style: IconButtons.storyButtons,
              onPressed: () => showStoryStickerSheet(Get.context!, controller),
              child: const Icon(
                CupertinoIcons.sparkles,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          Expanded(
            child: Obx(
              () => IconButton(
                icon: Icon(
                  CupertinoIcons.music_note_2,
                  color: controller.isMusicPlaying.value
                      ? Colors.blueAccent
                      : Colors.white,
                  size: 30,
                ),
                onPressed: () {
                  if (controller.isMusicPlaying.value) {
                    controller.pauseMusic();
                  } else {
                    controller.selectMusic();
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: Obx(
              () => TextButton(
                style: IconButtons.storyButtons,
                onPressed: controller.changeCircleColor,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: controller.color.value,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
