import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:turqappv2/Core/BottomSheets/NoYesAlert.dart';
import 'package:turqappv2/Core/Functions.dart';
import 'package:turqappv2/Core/RozetContent.dart';
import 'package:turqappv2/Modules/SocialProfile/SocialProfile.dart';
import 'package:turqappv2/Modules/Story/StoryViewer/UserStoryContentController.dart';
import 'package:turqappv2/Services/FirebaseMyStore.dart';
import 'package:turqappv2/Services/StoryInteractionOptimizer.dart';
import '../StoryMaker/StoryMakerController.dart';
import '../StoryRow/StoryUserModel.dart';
import '../StoryRow/StoryRowController.dart';
import 'StoryElements.dart';
import 'StoryVideoWidget.dart';

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
  PlayerState _musicState = PlayerState.stopped;
  late UserStoryContentController controller;
  Timer? _musicStartFallbackTimer;

  @override
  void initState() {
    super.initState();
    _configurePlayerContext();
    // Başlangıç indexini "kaldığı yerden devam" kuralına göre ayarla
    storyIndex = (widget.initialStoryIndex >= 0 &&
            widget.initialStoryIndex < widget.user.stories.length)
        ? widget.initialStoryIndex
        : 0;
    _initializeController();
    _musicStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _musicState = state;
      });
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

  void _closeStoryViewer() {
    _timer?.cancel();
    _audioPlayer.stop();
    _musicStateSubscription?.cancel();
    _musicStartFallbackTimer?.cancel();
    Get.back();
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
          child: Container(
            key: ValueKey('story_container_${currentStory.id}'),
            color: currentStory.backgroundColor.alpha == 0
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
                              return const SizedBox.shrink();
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
                            default:
                              return const SizedBox.shrink();
                          }
                        }),
                        // Basılı tutulduğunda görsel duraklatma bildirimi
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedOpacity(
                              opacity: _isHoldPaused ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 120),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.35),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(CupertinoIcons.play,
                                          color: Colors.white, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
        margin: const EdgeInsets.symmetric(horizontal: 2),
        height: 3, // Biraz daha kalın yap
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: MediaQuery.of(context).size.width *
                  value.clamp(0.0, 1.0) /
                  widget.user.stories.length,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 2,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget userInfo(StoryUserModel currentUser) {
    final currentStory = currentUser.stories[storyIndex];
    final hasMusic =
        currentStory.musicUrl.isNotEmpty;

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
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10, top: 15),
      child: Row(
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
                        FirebaseAuth.instance.currentUser!.uid, onClosed: (v) {
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
                    SizedBox(
                      width: 7,
                    ),
                    Text(
                      "Yorumlar",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: "MontserratMedium"),
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
                controller.showLikesBottomSheet(currentStory.id, onClosed: (v) {
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
                    SizedBox(
                      width: 7,
                    ),
                    Text(
                      "Beğeniler",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: "MontserratMedium"),
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
              controller.showSeensBottomSheet(currentStory.id, onClosed: (v) {
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
          SizedBox(
            width: 12,
          ),
          GestureDetector(
            onTap: () {
              noYesAlert(
                  title: "Sil",
                  message: "Bu hikaye silinsin mi?",
                  onYesPressed: () async {
                    final currentStory = widget.user.stories[storyIndex];
                    await deleteStory(
                        userId: widget.user.userID, storyId: currentStory.id);

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
    );
  }

  Widget otherToolBar() {
    final currentStory = widget.user.stories[storyIndex];
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10, top: 15),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                _audioPlayer.pause();
                _timer?.cancel();
                controller.showPostCommentsBottomSheet(
                    currentStory.id,
                    widget.user.nickname,
                    widget.user.userID ==
                        FirebaseAuth.instance.currentUser!.uid, onClosed: (v) {
                  _startProgress();
                  _audioPlayer.resume();
                });
              },
              child: Container(
                height: 50,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(50),
                    borderRadius: BorderRadius.all(Radius.circular(50))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Text(
                    "${widget.user.nickname} için yorum ekle..",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: "MontserratMedium"),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 12,
          ),
          Obx(() {
            return GestureDetector(
              onTap: () {
                controller.like(currentStory.id);
              },
              onLongPress: () {
                _audioPlayer.pause();
                _timer?.cancel();
                controller.showLikesBottomSheet(currentStory.id, onClosed: (v) {
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
                      SizedBox(
                        width: 7,
                      ),
                      Text(
                        controller.likeCount.value.toString(),
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontFamily: "MontserratMedium"),
                      ),
                    ],
                  ),
                ),
              ),
            );
          })
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
          .collection("Stories")
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
