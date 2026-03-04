import 'dart:async';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Services/audio_focus_coordinator.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/user_story_content_controller.dart';
import 'package:turqappv2/Services/firebase_my_store.dart';
import 'package:turqappv2/Services/story_interaction_optimizer.dart';
import '../StoryMaker/story_maker_controller.dart';
import '../StoryRow/story_user_model.dart';
import '../StoryRow/story_row_controller.dart';
import 'story_elements.dart';
import 'story_video_widget.dart';
import '../StoryHighlights/highlight_picker_sheet.dart';
import 'package:share_plus/share_plus.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:turqappv2/Core/Services/conversation_id.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import '../../Chat/chat.dart';

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

  void _initializeController() {
    if (widget.user.stories.isNotEmpty &&
        storyIndex < widget.user.stories.length) {
      controller = Get.put(
          UserStoryContentController(
              storyID: widget.user.stories[storyIndex].id,
              nickname: widget.user.nickname,
              isMyStory:
                  widget.user.userID == FirebaseAuth.instance.currentUser!.uid),
          tag: '${widget.user.userID}_$storyIndex');
    }
  }

  void _updateController() {
    if (widget.user.stories.isNotEmpty &&
        storyIndex < widget.user.stories.length) {
      try {
        Get.delete<UserStoryContentController>(
            tag: '${widget.user.userID}_${storyIndex - 1}');
      } catch (e) {
        // Controller bulunamadıysa devam et
      }
      controller = Get.put(
          UserStoryContentController(
              storyID: widget.user.stories[storyIndex].id,
              nickname: widget.user.nickname,
              isMyStory:
                  widget.user.userID == FirebaseAuth.instance.currentUser!.uid),
          tag: '${widget.user.userID}_$storyIndex');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _musicStateSubscription?.cancel();
    _musicStartFallbackTimer?.cancel();
    AudioFocusCoordinator.instance.unregisterAudioPlayer(_audioPlayer);
    _audioPlayer.dispose();
    try {
      Get.delete<UserStoryContentController>(
          tag: '${widget.user.userID}_$storyIndex');
    } catch (e) {
      // Controller bulunamadıysa devam et
    }
    super.dispose();
  }

  Future<void> _startOrWait() async {
    _timer?.cancel();
    _musicStateSubscription?.cancel();

    // İndex doğrulaması
    if (storyIndex >= widget.user.stories.length || storyIndex < 0) {
      print("⚠️ Invalid story index: $storyIndex");
      return;
    }

    setState(() {
      progress = 0.0;
      _waitingForMusic = false;
    });

    final currentStory = widget.user.stories[storyIndex];
    print("🎥 Starting story: ${currentStory.id} (Index: $storyIndex)");

    controller.getLikes(currentStory.id);
    controller.setSeen(currentStory.id);
    final videoElement = currentStory.elements
        .firstWhereOrNull((e) => e.type == StoryElementType.video);
    // --- MÜZİK VARSA ---
    if (currentStory.musicUrl != "" && currentStory.musicUrl.isNotEmpty) {
      progressMaxDuration = const Duration(seconds: 30); // 30 sn!
      if (_currentMusicUrl != currentStory.musicUrl) {
        _currentMusicUrl = currentStory.musicUrl;

        // Önce stop (varsa)
        await _audioPlayer.stop();

        setState(() {
          _waitingForMusic = true;
        });
        // Güvenli fallback: 2 saniye içinde playing olmazsa ilerlemeyi başlat
        _musicStartFallbackTimer?.cancel();
        _musicStartFallbackTimer = Timer(const Duration(seconds: 2), () {
          if (mounted && _waitingForMusic) {
            _waitingForMusic = false;
            _startProgress();
          }
        });

        // Dinleyici kur
        _musicStateSubscription =
            _audioPlayer.onPlayerStateChanged.listen((state) {
          if (state == PlayerState.playing && _waitingForMusic) {
            setState(() {
              _waitingForMusic = false;
            });
            _startProgress();
          }
        });

        // Play müzik ve state değişimini bekle
        try {
          await _audioPlayer.setVolume(1);
          await _audioPlayer.play(UrlSource(_currentMusicUrl!));
        } catch (e) {
          print("Müzik yüklenemedi: $e");
          _waitingForMusic = false;
          _startProgress(); // fallback
        }
      } else {
        // Aynı müzikse resume et ve bekle
        await _audioPlayer.setVolume(1);
        await _audioPlayer.resume();
        setState(() {
          _waitingForMusic = true;
        });
        _musicStateSubscription =
            _audioPlayer.onPlayerStateChanged.listen((state) {
          if (state == PlayerState.playing && _waitingForMusic) {
            setState(() {
              _waitingForMusic = false;
            });
            _startProgress();
          }
        });
        // Güvenli fallback: 2 saniye içinde playing olmazsa ilerlemeyi başlat
        _musicStartFallbackTimer?.cancel();
        _musicStartFallbackTimer = Timer(const Duration(seconds: 2), () {
          if (mounted && _waitingForMusic) {
            _waitingForMusic = false;
            _startProgress();
          }
        });
      }
      // NOT: progress burada başlamaz, state playing'e geçince başlayacak!
    } else {
      // --- MÜZİK YOKSA ---
      progressMaxDuration = const Duration(seconds: 15);
      _currentMusicUrl = null;
      await _audioPlayer.stop();
      if (videoElement != null) {
        setState(() {
          _waitingForVideo = true;
        });
      } else {
        setState(() {
          _waitingForVideo = false;
        });
        _startProgress();
      }
    }
  }

  void _startProgress() {
    _timer?.cancel();
    const updateInterval = Duration(milliseconds: 50);
    final increment =
        updateInterval.inMilliseconds / progressMaxDuration.inMilliseconds;

    _timer = Timer.periodic(updateInterval, (timer) {
      if (mounted) {
        setState(() {
          progress += increment;
          if (progress >= 1.0) {
            progress = 1.0;
            _timer?.cancel();
            print("⏱️ Story progress completed - Auto next");
            _nextStory(auto: true);
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _nextStory({bool auto = false}) async {
    await _audioPlayer.stop(); // story değişince müzik durdur
    _musicStateSubscription?.cancel();

    if (storyIndex < widget.user.stories.length - 1) {
      final newIndex = storyIndex + 1;
      print(
          "➡️ Next Story: $storyIndex -> $newIndex (${widget.user.stories[newIndex].id})");

      // Mevcut hikayeyi izlendi olarak işaretle (ara güncelleme)
      _markCurrentStoryAsSeen();

      setState(() {
        storyIndex = newIndex;
        progress = 0.0; // Progress'i sıfırla
      });

      _updateController(); // Controller'ı güncelle
      await Future.delayed(const Duration(
          milliseconds: 50)); // UI güncellemesi için kısa bekleme
      _startOrWait();
    } else {
      _timer?.cancel();
      widget.onUserStoryFinished?.call();
    }
  }

  void _prevStory() async {
    await _audioPlayer.stop(); // story değişince müzik durdur
    _musicStateSubscription?.cancel();

    if (storyIndex > 0) {
      final newIndex = storyIndex - 1;
      print(
          "⬅️ Prev Story: $storyIndex -> $newIndex (${widget.user.stories[newIndex].id})");

      setState(() {
        storyIndex = newIndex;
        progress = 0.0; // Progress'i sıfırla
      });

      _updateController(); // Controller'ı güncelle
      await Future.delayed(const Duration(
          milliseconds: 50)); // UI güncellemesi için kısa bekleme
      _startOrWait();
    } else {
      widget.onPrevUserRequested?.call();
    }
  }

  /// Mevcut hikayeyi optimize edilmiş sistemle işaretle
  void _markCurrentStoryAsSeen() {
    if (storyIndex < widget.user.stories.length) {
      final currentStory = widget.user.stories[storyIndex];
      final userID = widget.user.userID;

      // Optimize edilmiş debounced marking (500ms batch)
      StoryInteractionOptimizer.to.markStoryViewed(userID, currentStory.id,
          currentStory.createdAt.millisecondsSinceEpoch);
    }
  }

  // Parent (StoryViewer) upward swipe triggers this to open comments
  Future<void> openCommentsFromParent() async {
    if (!mounted) return;
    final currentStory = widget.user.stories[storyIndex];
    try {
      FocusScope.of(context).unfocus();
      _audioPlayer.pause();
      _timer?.cancel();
      await controller.showPostCommentsBottomSheet(
        currentStory.id,
        widget.user.nickname,
        widget.user.userID == FirebaseAuth.instance.currentUser!.uid,
        onClosed: (v) {
          if (!mounted) return;
          _startProgress();
          _audioPlayer.resume();
        },
      );
    } catch (_) {}
  }

  // Page-level swipe handled in StoryViewer

  @override
  Widget build(BuildContext context) {
    // Eğer story tamamen silinmişse veya index bozuksa:
    if (widget.user.stories.isEmpty ||
        storyIndex < 0 ||
        storyIndex >= widget.user.stories.length) {
      // Ana sayfaya dön veya bir üst seviyeye çık, ya da sadece boş widget dön
      Future.microtask(() {
        widget.onUserStoryFinished?.call();
      });
      return const SizedBox.shrink(); // veya bir loading gösterebilirsin
    }

    // Debug: Hangi hikayenin gösterildiğini kontrol et
    print(
        "📺 Building story content - User: ${widget.user.nickname}, Story Index: $storyIndex/${widget.user.stories.length - 1}, Story ID: ${widget.user.stories[storyIndex].id}");

    final totalStories = widget.user.stories.length;
    final currentStory = widget.user.stories[storyIndex];
    final sortedElements = [...currentStory.elements]
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    print(
        "🎨 Rendering story elements: ${sortedElements.length} elements for story ${currentStory.id}");

    return Column(
      key: ValueKey('story_column_${currentStory.id}'),
      children: [
        Padding(
          padding:
              const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 0),
          child: Row(
            children: List.generate(totalStories, (i) {
              if (i < storyIndex) {
                // Tamamlanmış hikayeler
                return _buildProgressBar(1.0);
              } else if (i == storyIndex) {
                // Mevcut hikaye
                return _buildProgressBar(progress);
              } else {
                // Henüz başlamamış hikayeler
                return _buildProgressBar(0.0);
              }
            }),
          ),
        ),
        userInfo(widget.user),
        Expanded(
          child: RepaintBoundary(
            key: _repaintKey,
            child: Container(
              key: ValueKey('story_container_${currentStory.id}'),
              color: (currentStory.backgroundColor.a * 255.0)
                          .round()
                          .clamp(0, 255) ==
                      0
                  ? Colors.transparent
                  : currentStory.backgroundColor,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // Yatay swipe: PageView (StoryViewer) tarafından yönetilsin
                onTapUp: (details) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  if (_tapLocked) return;

                  // Tap lock mekanizması
                  _tapLocked = true;
                  Future.delayed(const Duration(milliseconds: 200), () {
                    if (mounted) _tapLocked = false;
                  });

                  // Ekran genisliginin ortasına göre karar ver
                  if (details.localPosition.dx > screenWidth / 2) {
                    print("➡️ Right tap - Next story");
                    _nextStory();
                  } else {
                    print("⬅️ Left tap - Previous story");
                    _prevStory();
                  }
                },
                onLongPressStart: (_) {
                  print("⏸️ Story paused - Long press started");
                  setState(() {
                    _isHoldPaused = true;
                  });
                  _timer?.cancel();
                  _audioPlayer.pause();
                },
                onLongPressEnd: (_) {
                  print("▶️ Story resumed - Long press ended");
                  setState(() {
                    _isHoldPaused = false;
                  });
                  _startProgress();
                  _audioPlayer.resume();
                },
                child: _waitingForMusic
                    ? const Center(child: CupertinoActivityIndicator())
                    : Stack(
                        // Key ekleyerek Stack'in yeniden render olmasını sağla
                        key: ValueKey(
                            'story_stack_${currentStory.id}_$storyIndex'),
                        children: [
                          ...sortedElements.map((element) {
                            switch (element.type) {
                              case StoryElementType.image:
                                return StoryImageWidget(
                                  key: ValueKey(
                                      'img_${element.content}_${currentStory.id}'),
                                  element: element,
                                );
                              case StoryElementType.gif:
                                return StoryGifWidget(
                                  key: ValueKey(
                                      'gif_${element.content}_${currentStory.id}'),
                                  element: element,
                                );
                              case StoryElementType.text:
                                return StoryTextWidget(
                                  key: ValueKey(
                                      'txt_${element.content}_${currentStory.id}'),
                                  element: element,
                                );
                              case StoryElementType.video:
                                return StoryVideoWidget(
                                  key: ValueKey(
                                      'vid_${element.content}_${currentStory.id}'),
                                  element: element,
                                  maxDuration: const Duration(seconds: 60),
                                  paused: _isHoldPaused,
                                  onStarted: (Duration actualDuration) {
                                    final effective = actualDuration >
                                            const Duration(seconds: 60)
                                        ? const Duration(seconds: 60)
                                        : actualDuration;
                                    if (_waitingForVideo) {
                                      setState(() {
                                        progress = 0.0;
                                        progressMaxDuration = effective;
                                        _waitingForVideo = false;
                                      });
                                      _startProgress();
                                    }
                                  },
                                  onEnded: () {
                                    _nextStory(auto: true);
                                  },
                                );
                              case StoryElementType.sticker:
                                return StoryTextWidget(
                                  key: ValueKey(
                                      'sticker_${element.content}_${currentStory.id}'),
                                  element: element,
                                );
                              default:
                                return const SizedBox.shrink();
                            }
                          }),
                          // Instagram-style: pause sadece progress bar'ı durdurur, görsel overlay yok
                        ],
                      ),
              ),
            ),
          ),
        ),
        if (currentStory.userId == FirebaseAuth.instance.currentUser!.uid)
          myToolBar()
        else
          otherToolBar()
      ],
    );
  }

  Widget _buildProgressBar(double value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        height: 2.5,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(1.5),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget userInfo(StoryUserModel currentUser) {
    final currentStory = currentUser.stories[storyIndex];
    final hasMusic = currentStory.musicUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              _audioPlayer.pause();
              Get.to(() => SocialProfile(userID: currentUser.userID))
                  ?.then((_) {
                _audioPlayer.resume();
              });
            },
            child: ClipOval(
              child: SizedBox(
                width: 33,
                height: 33,
                child: currentUser.pfImage.isNotEmpty
                    ? CachedNetworkImage(
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        imageUrl: currentUser.pfImage,
                        fit: BoxFit.cover,
                      )
                    : const Center(
                        child: CupertinoActivityIndicator(),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nickname + rozet + zaman yatay scrollable!
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _audioPlayer.pause();
                          Get.to(() =>
                                  SocialProfile(userID: currentUser.userID))
                              ?.then((_) {
                            _audioPlayer.resume();
                          });
                        },
                        child: Text(
                          currentUser.nickname,
                          // Sadece burada maxLines yok!
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      RozetContent(size: 13, userID: currentUser.userID),
                      const SizedBox(width: 4),
                      Text(
                        timeAgoMetin(
                            currentStory.createdAt.millisecondsSinceEpoch),
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ],
                  ),
                ),
                // Eğer müzik varsa yatay scrollable music
                if (hasMusic)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.music_note_2,
                              color: Colors.white, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            getMusicNameFromURL(currentStory.musicUrl),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(
              CupertinoIcons.clear,
              size: 25,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget myToolBar() {
    final currentStory = widget.user.stories[storyIndex];

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10, top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reaction counts for my story
          Obx(() {
            final counts = controller.reactionCounts;
            if (counts.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: counts.entries
                    .where((e) => e.value > 0)
                    .map((e) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(e.key, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 3),
                              Text(
                                e.value.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: "MontserratMedium",
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            );
          }),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    _audioPlayer.pause();
                    _timer?.cancel();
                    await controller.showPostCommentsBottomSheet(
                        currentStory.id,
                        widget.user.nickname,
                        widget.user.userID ==
                            FirebaseAuth.instance.currentUser!.uid,
                        onClosed: (v) {
                      _startProgress();
                      _audioPlayer.resume();
                    });
                  },
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(50),
                        borderRadius: BorderRadius.all(Radius.circular(50))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.bubble_left_bubble_right,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 12,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _audioPlayer.pause();
                    _timer?.cancel();
                    controller.showLikesBottomSheet(currentStory.id,
                        onClosed: (v) {
                      _startProgress();
                      _audioPlayer.resume();
                    });
                  },
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(50),
                        borderRadius: BorderRadius.all(Radius.circular(50))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.hand_thumbsup,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 12,
              ),
              GestureDetector(
                onTap: () {
                  _audioPlayer.pause();
                  _timer?.cancel();
                  controller.showSeensBottomSheet(currentStory.id,
                      onClosed: (v) {
                    _startProgress();
                    _audioPlayer.resume();
                  });
                },
                child: Container(
                  height: 50,
                  width: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(50), shape: BoxShape.circle),
                  child: Icon(
                    CupertinoIcons.eyeglasses,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // One Cikar (Highlight) button
              GestureDetector(
                onTap: () {
                  _audioPlayer.pause();
                  _timer?.cancel();
                  Get.bottomSheet(
                    HighlightPickerSheet(storyId: currentStory.id),
                    isScrollControlled: true,
                    isDismissible: true,
                    enableDrag: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    backgroundColor: Colors.white,
                  ).then((_) {
                    _startProgress();
                    _audioPlayer.resume();
                  });
                },
                child: Container(
                  height: 50,
                  width: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.bookmark,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Download button
              GestureDetector(
                onTap: () async {
                  try {
                    _timer?.cancel();
                    final boundary = _repaintKey.currentContext
                        ?.findRenderObject() as RenderRepaintBoundary?;
                    if (boundary == null) return;
                    final image = await boundary.toImage(pixelRatio: 3.0);
                    final byteData =
                        await image.toByteData(format: ui.ImageByteFormat.png);
                    if (byteData == null) return;
                    final pngBytes = byteData.buffer.asUint8List();
                    final result = await SaverGallery.saveImage(
                      pngBytes,
                      fileName:
                          'story_${DateTime.now().millisecondsSinceEpoch}.png',
                      androidRelativePath: 'Pictures/TurqApp',
                      skipIfExists: false,
                    );
                    if (result.isSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Hikaye galeriye kaydedildi'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    print('Story download error: $e');
                  } finally {
                    _startProgress();
                  }
                },
                child: Container(
                  height: 50,
                  width: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.arrow_down_to_line,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  noYesAlert(
                      title: "Sil",
                      message: "Bu hikaye silinsin mi?",
                      onYesPressed: () async {
                        final currentStory = widget.user.stories[storyIndex];
                        await deleteStory(
                            userId: widget.user.userID,
                            storyId: currentStory.id);

                        setState(() {
                          widget.user.stories.removeAt(storyIndex);

                          // --- Burayı daha güvenli hale getiriyoruz ---
                          if (widget.user.stories.isEmpty) {
                            // Hiç hikaye kalmadıysa
                            widget.onUserStoryFinished?.call();
                            return;
                          }

                          // Eğer index out of range olduysa, sonuncu hikayeye çek
                          if (storyIndex >= widget.user.stories.length) {
                            storyIndex = widget.user.stories.length - 1;
                          }
                        });

                        // Kaldığı yerden devam et (artık stories boş değilse)
                        if (widget.user.stories.isNotEmpty) {
                          _updateController(); // Controller'ı güncelle
                          _startOrWait();
                        }
                      });
                },
                child: Container(
                  height: 50,
                  width: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.trash,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget otherToolBar() {
    final currentStory = widget.user.stories[storyIndex];
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10, top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reaction emoji row
          Obx(() {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: UserStoryContentController.reactionEmojis.map((emoji) {
                final isSelected = controller.myReaction.value == emoji;
                return GestureDetector(
                  onTap: () => controller.react(currentStory.id, emoji),
                  child: AnimatedScale(
                    scale: isSelected ? 1.3 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.grey.withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }),
          const SizedBox(height: 8),
          // Comment + like row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _audioPlayer.pause();
                    _timer?.cancel();
                    final myUid = FirebaseAuth.instance.currentUser!.uid;
                    final chatId =
                        buildConversationId(myUid, widget.user.userID);
                    Get.to(() => ChatView(
                          chatID: chatId,
                          userID: widget.user.userID,
                          isNewChat: true,
                          openKeyboard: true,
                        ))?.then((_) {
                      if (mounted) {
                        _startProgress();
                        _audioPlayer.resume();
                      }
                    });
                  },
                  child: Container(
                    height: 50,
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(50),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(50))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Text(
                        "${widget.user.nickname}'a mesaj gonder..",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: "MontserratMedium"),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Obx(() {
                return GestureDetector(
                  onTap: () {
                    controller.like(currentStory.id);
                  },
                  onLongPress: () {
                    _audioPlayer.pause();
                    _timer?.cancel();
                    controller.showLikesBottomSheet(currentStory.id,
                        onClosed: (v) {
                      _startProgress();
                      _audioPlayer.resume();
                    });
                  },
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(50),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(50))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            controller.isLikedMe.value
                                ? CupertinoIcons.hand_thumbsup_fill
                                : CupertinoIcons.hand_thumbsup,
                            color: controller.isLikedMe.value
                                ? Colors.blueAccent
                                : Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            controller.likeCount.value.toString(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontFamily: "MontserratMedium"),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 8),
              // Share button
              GestureDetector(
                onTap: () async {
                  _audioPlayer.pause();
                  _timer?.cancel();
                  try {
                    final currentStory = widget.user.stories[storyIndex];
                    String previewImage = '';
                    if (currentStory.elements.isNotEmpty) {
                      previewImage = currentStory.elements
                          .firstWhere(
                            (e) => e.type == StoryElementType.image,
                            orElse: () => currentStory.elements.first,
                          )
                          .content;
                    }
                    final shortUrl = await ShortLinkService().getStoryPublicUrl(
                      storyId: currentStory.id,
                      title: '${widget.user.nickname} hikayesi',
                      desc: 'TurqApp üzerinde hikayeyi görüntüle',
                      imageUrl: previewImage.isEmpty ? null : previewImage,
                    );
                    await SharePlus.instance.share(
                      ShareParams(
                        text:
                            '${widget.user.nickname} hikayesine bak!\n$shortUrl',
                      ),
                    );
                  } catch (_) {}
                  _startProgress();
                  _audioPlayer.resume();
                },
                child: Container(
                  height: 50,
                  width: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.share_up,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> deleteStory(
      {required String userId, required String storyId}) async {
    try {
      // Silmek yerine işaretle: deleted = true
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await FirebaseFirestore.instance
          .collection("stories")
          .doc(storyId)
          .update(
              {'deleted': true, 'deletedAt': nowMs, 'deleteReason': 'manual'});
    } catch (e) {
      print('deleteStory update error: $e');
    }

    // Story refresh
    try {
      await Get.find<StoryRowController>().loadStories();
      final cont = Get.find<FirebaseMyStore>();
      cont.hasStoryOwner();
      print("🗑️ Story deleted and refreshed");
    } catch (e) {
      print("🗑️ Story delete refresh error: $e");
    }
  }
}
