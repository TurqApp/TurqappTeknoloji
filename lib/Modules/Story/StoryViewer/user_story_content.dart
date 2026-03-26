import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/Services/audio_focus_coordinator.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/story_music_library_service.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/Utils/url_utils.dart';
import 'package:turqappv2/Core/Widgets/shared_post_label.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Modules/Story/DeletedStories/deleted_stories_controller.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/user_story_content_controller.dart';
import 'package:turqappv2/Services/story_interaction_optimizer.dart';
import '../StoryMaker/story_maker_controller.dart';
import '../StoryRow/story_user_model.dart';
import '../StoryRow/story_row_controller.dart';
import '../StoryMusic/story_music_profile_view.dart';
import 'story_elements.dart';
import 'story_video_widget.dart';
import '../StoryHighlights/highlight_picker_sheet.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'user_story_content_playback_part.dart';
part 'user_story_content_view_part.dart';
part 'user_story_content_toolbar_part.dart';

class UserStoryContent extends StatefulWidget {
  final StoryUserModel user;
  final VoidCallback? onUserStoryFinished;
  final VoidCallback? onPrevUserRequested;
  final VoidCallback? onSwipeNextUser;
  final VoidCallback? onSwipePrevUser;
  final int initialStoryIndex;

  const UserStoryContent({
    required this.user,
    this.onUserStoryFinished,
    this.onPrevUserRequested,
    this.onSwipeNextUser,
    this.onSwipePrevUser,
    this.initialStoryIndex = 0,
    super.key,
  });

  @override
  State<UserStoryContent> createState() => _UserStoryContentState();
}

class _UserStoryContentState extends State<UserStoryContent>
    with TickerProviderStateMixin {
  int storyIndex = 0;
  double progress = 0.0;
  Timer? _timer;
  Duration progressMaxDuration = const Duration(seconds: 15);
  bool _waitingForVideo = false;
  // Tap debouncing - Instagram benzeri smooth navigasyon için
  bool _tapLocked = false;
  bool _isHoldPaused = false; // basılı tutma ile duraklatma
  final GlobalKey _repaintKey = GlobalKey();

  // --- Müzik için ---
  final AudioPlayer _audioPlayer = AudioPlayer();

  void _configurePlayerContext() {
    try {
      _audioPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
        ),
      );
    } catch (_) {}
  }

  String? _currentMusicUrl;
  StreamSubscription<PlayerState>? _musicStateSubscription;
  bool _waitingForMusic = false; // ek: müzik başlaması bekleniyor
  late UserStoryContentController controller;
  Timer? _musicStartFallbackTimer;

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  @override
  void initState() {
    super.initState();
    AudioFocusCoordinator.instance.registerAudioPlayer(_audioPlayer);
    _configurePlayerContext();
    // Başlangıç indexini "kaldığı yerden devam" kuralına göre ayarla
    storyIndex = (widget.initialStoryIndex >= 0 &&
            widget.initialStoryIndex < widget.user.stories.length)
        ? widget.initialStoryIndex
        : 0;
    _initializeController();
    _musicStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      // Mevcut startOrWait logic burada zaten var
      if (state == PlayerState.playing && _waitingForMusic) {
        setState(() {
          _waitingForMusic = false;
        });
        _startProgress();
      }
    });
    _startOrWait();
  }

  @override
  Widget build(BuildContext context) => buildContent(context);

  String _controllerTagFor(int index) => '${widget.user.userID}_$index';

  void _initializeController() {
    if (widget.user.stories.isNotEmpty &&
        storyIndex < widget.user.stories.length) {
      controller = ensureUserStoryContentController(
        tag: _controllerTagFor(storyIndex),
        storyID: widget.user.stories[storyIndex].id,
        nickname: widget.user.nickname,
        isMyStory: widget.user.userID == _currentUid,
      );
    }
  }

  void _updateController() {
    if (widget.user.stories.isNotEmpty &&
        storyIndex < widget.user.stories.length) {
      final previousTag = _controllerTagFor(storyIndex - 1);
      if (maybeFindUserStoryContentController(tag: previousTag) != null) {
        try {
          Get.delete<UserStoryContentController>(tag: previousTag);
        } catch (e) {
          // Controller bulunamadıysa devam et
        }
      }
      controller = ensureUserStoryContentController(
        tag: _controllerTagFor(storyIndex),
        storyID: widget.user.stories[storyIndex].id,
        nickname: widget.user.nickname,
        isMyStory: widget.user.userID == _currentUid,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _musicStateSubscription?.cancel();
    _musicStartFallbackTimer?.cancel();
    AudioFocusCoordinator.instance.unregisterAudioPlayer(_audioPlayer);
    _audioPlayer.dispose();
    final tag = _controllerTagFor(storyIndex);
    if (identical(maybeFindUserStoryContentController(tag: tag), controller)) {
      try {
        Get.delete<UserStoryContentController>(tag: tag);
      } catch (e) {
        // Controller bulunamadıysa devam et
      }
    }
    super.dispose();
  }

  StoryElement? _sourceProfileBadgeForStory(StoryUserModel currentUser) {
    if (storyIndex < 0 || storyIndex >= currentUser.stories.length) {
      return null;
    }

    final currentStory = currentUser.stories[storyIndex];
    for (final element in currentStory.elements.reversed) {
      if (element.stickerType == 'source_profile') {
        return element;
      }
    }
    return null;
  }
}
