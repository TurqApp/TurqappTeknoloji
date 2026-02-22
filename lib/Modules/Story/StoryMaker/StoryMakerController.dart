import 'dart:io';
import 'package:turqappv2/Core/AppSnackbar.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:turqappv2/Modules/SpotifySelector/SpotifySelector.dart';
import 'package:path/path.dart' as path;
import 'package:turqappv2/Modules/Story/StoryRow/StoryRowController.dart';
import 'package:turqappv2/Services/FirebaseMyStore.dart';
import 'package:turqappv2/Core/Utils/CdnUrlBuilder.dart';
import 'package:video_player/video_player.dart';
import '../../../Core/AppSnackbar.dart';
import '../../../Core/Services/OptimizedNSFWService.dart';
import 'package:turqappv2/Core/BottomSheets/NoYesAlert.dart';
import 'DrawingScreen.dart';
import 'dart:ui' as ui;

enum StoryElementType {
  video,
  image,
  text,
  sticker,
  gif,
  drawing,
}

class StoryElement {
  final String id;
  StoryElementType type;
  String content;
  double width;
  double height;
  Offset position;
  double rotation;
  int zIndex;
  bool isMuted;
  double fontSize;
  double aspectRatio;
  int textColor;
  int textBgColor;
  bool hasTextBg;
  String textAlign;
  String fontWeight;
  bool italic;
  bool underline;
  double shadowBlur;
  double shadowOpacity;
  Offset? initialFocalPoint;
  Offset? initialPosition;
  double? initialWidth;
  double? initialHeight;
  double? initialRotation;
  double? initialFontSize;

  StoryElement({
    String? id,
    required this.type,
    required this.content,
    required this.width,
    required this.height,
    required this.position,
    this.rotation = 0,
    this.zIndex = 0,
    this.isMuted = false,
    this.fontSize = 20,
    this.aspectRatio = 1.0,
    this.textColor = 0xFFFFFFFF,
    this.textBgColor = 0x66000000,
    this.hasTextBg = false,
    this.textAlign = 'center',
    this.fontWeight = 'regular',
    this.italic = false,
    this.underline = false,
    this.shadowBlur = 2.0,
    this.shadowOpacity = 0.6,
    this.initialFocalPoint,
    this.initialPosition,
    this.initialWidth,
    this.initialHeight,
    this.initialRotation,
    this.initialFontSize,
  }) : id = id ?? _generateId();

  static String _generateId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart =
        List.generate(5, (_) => random.nextInt(36).toRadixString(36)).join();
    return 'element_$timestamp$randomPart';
  }
}

// 📁 lib/Modules/Story/StoryMaker/StoryMakerController.dart

class StoryMakerController extends GetxController {
  // Arka plan varsayılanı: şeffaf
  final Rx<Color> color = Colors.transparent.obs;
  RxList<StoryElement> elements = <StoryElement>[].obs;
  var music = "".obs;

  // Drag-to-delete için
  RxBool isDragging = false.obs;
  StoryElement? draggedElement;
  RxBool isElementOverTrash = false.obs;
  Offset? lastFingerPosition;
  final List<Color> colorOptions = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.white,
    Colors.grey.withAlpha(50),
    Colors.black,
  ];

  int _colorIndex = 0;
  int _zIndexCounter = 0;

  // Undo/Redo için history
  final List<List<StoryElement>> _history = [];
  int _historyIndex = -1;
  final int _maxHistorySize = 20;

  // Reactive variables for undo/redo state
  RxBool canUndo = false.obs;
  RxBool canRedo = false.obs;

  // Story upload state
  static RxBool isUploadingStory = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Initial state'i save et
    _saveState();
  }

  @override
  void onClose() {
    // AudioPlayer'ı güvenli şekilde dispose et
    try {
      if (_audioPlayer.state != PlayerState.disposed) {
        _audioPlayer.stop().then((_) {
          _audioPlayer.dispose();
        }).catchError((e) {
          print("AudioPlayer dispose error (ignored): $e");
          // Dispose yine de çağır
          try {
            _audioPlayer.dispose();
          } catch (disposeError) {
            print("AudioPlayer final dispose error (ignored): $disposeError");
          }
        });
      }
    } catch (e) {
      print("AudioPlayer onClose error (ignored): $e");
    }

    elements.clear();
    music.value = "";
    color.value = Colors.transparent;
    _colorIndex = 0;
    _zIndexCounter = 0;
    _history.clear();
    _historyIndex = -1;
    canUndo.value = false;
    canRedo.value = false;
    super.onClose();
  }

  void changeCircleColor() {
    color.value = colorOptions[_colorIndex];
    _colorIndex = (_colorIndex + 1) % colorOptions.length;
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    final nsfw = await OptimizedNSFWService.checkImage(file);
    if (nsfw.isNSFW) {
      AppSnackbar(
        "Yükleme Başarısız!",
        "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
        backgroundColor: Colors.red.withOpacity(0.7),
      );
      return;
    }

    // 2) Dosyayı belleğe oku ve çözümle
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final imgW = frame.image.width.toDouble();
    final imgH = frame.image.height.toDouble();

    // 3) Ekran boyutları
    final screenW = Get.width;
    final screenH = Get.height;

    // 4) "Contain" ölçekleme: aspect ratio koruyarak ekrana sığdır, zoom yapmadan
    final imgAspectRatio = imgW / imgH;
    final screenAspectRatio = screenW / screenH;

    double width, height;
    if (imgAspectRatio > screenAspectRatio) {
      // Image daha geniş, width'i ekrana sığdır
      width = screenW; // %90'ını kullan, yanlardan biraz boşluk
      height = width / imgAspectRatio;
    } else {
      // Image daha uzun, height'ı ekrana sığdır
      height = screenH; // Tam ekran yükseklik, üst boşluk yok
      width = height * imgAspectRatio;
    }

    // 5) Pozisyonlama - X ortala, Y üstten başla
    final dx = (screenW - width) / 2;
    // SafeArea, topBar ve bottomTools yüksekliklerini çıkar
    final topSafeArea = Get.mediaQuery.padding.top;
    final topBarHeight = 60.0;
    final bottomToolsHeight = 80.0;
    final playgroundHeight =
        screenH - topSafeArea - topBarHeight - bottomToolsHeight;
    final dy = (playgroundHeight - height) / 2; // Playground içinde ortala

    // 6) StoryElement ekle
    elements.add(
      StoryElement(
        type: StoryElementType.image,
        content: picked.path,
        width: width,
        height: height,
        position: Offset(dx, dy),
        rotation: 0,
        zIndex: ++_zIndexCounter,
        aspectRatio:
            double.parse((imgW / imgH).toStringAsFixed(4)), // 4 hane precision
      ),
    );

    // 7) History'ye kaydet - undo/redo butonları aktif olsun
    _saveState();
  }

  Future<void> pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;

    // NSFW kontrolü (video)
    final videoFile = File(picked.path);
    final nsfwVideo = await OptimizedNSFWService.checkVideo(videoFile);
    if (nsfwVideo.isNSFW) {
      AppSnackbar(
        "Yükleme Başarısız!",
        "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
        backgroundColor: Colors.red.withOpacity(0.7),
      );
      return;
    }

    // Geçici bir VideoPlayerController ile initialize edip
    // doğal boyutları alıyoruz:
    final tempController = VideoPlayerController.file(videoFile);
    await tempController.initialize();
    final videoSize = tempController.value.size; // Size(width, height)

    // Ekran boyutları
    final screenW = Get.width;
    final screenH = Get.height;

    // Video aspect ratio ve ekran aspect ratio
    final videoAspectRatio = videoSize.width / videoSize.height;
    final screenAspectRatio = screenW / screenH;

    double width, height;
    if (videoAspectRatio > screenAspectRatio) {
      // Video daha geniş, width'i ekrana sığdır
      width = screenW; // %90'ını kullan, yanlardan biraz boşluk
      height = width / videoAspectRatio;
    } else {
      // Video daha uzun, height'ı ekrana sığdır
      height = screenH; // Tam ekran yükseklik, üst boşluk yok
      width = height * videoAspectRatio;
    }

    // Playground alanı içinde ortalayarak pozisyonla
    final dx = (screenW - width) / 2;
    // SafeArea, topBar ve bottomTools yüksekliklerini çıkar
    final topSafeArea = Get.mediaQuery.padding.top;
    final topBarHeight = 60.0;
    final bottomToolsHeight = 80.0;
    final playgroundHeight =
        screenH - topSafeArea - topBarHeight - bottomToolsHeight;
    final dy = (playgroundHeight - height) / 2; // Playground içinde ortala

    // Controller'ı dispose et
    await tempController.dispose();

    // Son olarak öğeyi ekle
    final aspectRatio = double.parse(videoAspectRatio.toStringAsFixed(4));
    elements.add(
      StoryElement(
        type: StoryElementType.video,
        content: picked.path,
        width: width,
        height: height,
        position: Offset(dx, dy),
        rotation: 0,
        zIndex: ++_zIndexCounter,
        isMuted: false,
        aspectRatio: aspectRatio, // Video aspect ratio 4 hane
      ),
    );

    // History'ye kaydet - undo/redo butonları aktif olsun
    _saveState();
  }

  void bringToFront(StoryElement element) {
    element.zIndex = ++_zIndexCounter;
    elements.refresh();
  }

  void toggleVideoMute(StoryElement element) {
    if (element.type != StoryElementType.video) return;
    _saveState();
    element.isMuted = !element.isMuted;
    elements.refresh();
  }

  void removeElement(StoryElement element) {
    _saveState();
    elements.remove(element);
    elements.refresh();
  }

  void _saveState() {
    // Mevcut state'i deep copy yap
    final currentState = elements
        .map((e) => StoryElement(
              id: e.id,
              type: e.type,
              content: e.content,
              width: e.width,
              height: e.height,
              position: e.position,
              rotation: e.rotation,
              zIndex: e.zIndex,
              isMuted: e.isMuted,
              fontSize: e.fontSize,
              aspectRatio: e.aspectRatio,
              textColor: e.textColor,
              textBgColor: e.textBgColor,
              hasTextBg: e.hasTextBg,
              textAlign: e.textAlign,
              fontWeight: e.fontWeight,
              italic: e.italic,
              underline: e.underline,
              shadowBlur: e.shadowBlur,
              shadowOpacity: e.shadowOpacity,
            ))
        .toList();

    // History'ye ekle
    _historyIndex++;
    if (_historyIndex < _history.length) {
      _history.removeRange(_historyIndex, _history.length);
    }
    _history.add(currentState);

    // Max size kontrolü
    if (_history.length > _maxHistorySize) {
      _history.removeAt(0);
      _historyIndex--;
    }

    _updateUndoRedoState();
  }

  void _updateUndoRedoState() {
    canUndo.value = _historyIndex > 0;
    canRedo.value = _historyIndex < _history.length - 1;
  }

  void undo() {
    if (_historyIndex > 0) {
      _historyIndex--;
      elements.assignAll(_history[_historyIndex]);
      elements.refresh();
      _updateUndoRedoState();
    }
  }

  void redo() {
    if (_historyIndex < _history.length - 1) {
      _historyIndex++;
      elements.assignAll(_history[_historyIndex]);
      elements.refresh();
      _updateUndoRedoState();
    }
  }

  final AudioPlayer _audioPlayer = AudioPlayer();

  StoryMakerController() {
    // Android'te dinamik miksaj için bağlam ayarı
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

  var isMusicPlaying = false.obs;

  void selectMusic() async {
    final url = await Get.to<String>(
      SpotifySelector(url: (u) => u),
    );

    if (url != null && url.isNotEmpty) {
      // Dinamik: Video sesleri için kullanıcıya noYesAlert ile sor
      final hasAnyUnmutedVideo =
          elements.any((e) => e.type == StoryElementType.video && !e.isMuted);
      bool muteVideosDecision = false;
      if (hasAnyUnmutedVideo) {
        await noYesAlert(
          title: 'Video Sesleri',
          message:
              'Müzik eklemek üzeresiniz. Videoların sesini kapatmak ister misiniz?',
          yesText: 'Evet, Kapat',
          cancelText: 'Hayır',
          onYesPressed: () {
            muteVideosDecision = true;
          },
        );
      }
      if (muteVideosDecision) {
        for (var e in elements) {
          if (e.type == StoryElementType.video) {
            e.isMuted = true;
          }
        }
        elements.refresh();
      }

      // Önce önceki parçayı güvenli şekilde durdur
      try {
        if (_audioPlayer.state != PlayerState.disposed) {
          await _audioPlayer.stop();
        }
      } catch (e) {
        print("selectMusic stop error (ignored): $e");
      }

      // Yeni URL'i ayarla ve çalmaya başla
      try {
        if (_audioPlayer.state != PlayerState.disposed) {
          _audioPlayer.play(UrlSource(url)).then((v) {
            isMusicPlaying.value = true;
          }).catchError((e) {
            print("selectMusic play error: $e");
            isMusicPlaying.value = false;
          });
        }
      } catch (e) {
        print("selectMusic play error: $e");
        isMusicPlaying.value = false;
      }

      music.value = url;
      elements.refresh();
      print("🎵 MÜZİK ÇALIYOR: $url");
    }
  }

  void pauseMusic() {
    try {
      if (_audioPlayer.state != PlayerState.disposed) {
        _audioPlayer.pause();
      }
    } catch (e) {
      print("pauseMusic error (ignored): $e");
    }
    isMusicPlaying.value = false;
  }

  void stopMusic() {
    try {
      if (_audioPlayer.state != PlayerState.disposed) {
        _audioPlayer.stop();
      }
    } catch (e) {
      print("stopMusic error (ignored): $e");
    }
    isMusicPlaying.value = false;
  }

  void addTextElement(String text) {
    _saveState();
    const width = 250.0;
    const height = 120.0;
    elements.add(
      StoryElement(
        type: StoryElementType.text,
        content: text,
        width: width,
        height: height,
        position: Offset(100, 100),
        rotation: 0,
        zIndex: ++_zIndexCounter,
        fontSize: 20, // başlangıç fontsize
        aspectRatio: double.parse(
            (width / height).toStringAsFixed(4)), // Text container aspect ratio
      ),
    );
  }

  void addStyledTextElement(
    String text, {
    int textColor = 0xFFFFFFFF,
    int textBgColor = 0x66000000,
    bool hasTextBg = true,
    String textAlign = 'center',
    String fontWeight = 'regular',
    bool italic = false,
    bool underline = false,
    double shadowBlur = 2.0,
    double shadowOpacity = 0.6,
  }) {
    _saveState();
    const width = 280.0;
    const height = 140.0;
    // Playground merkezine konumla (Stack'in 0,0'ı playground'ın üstü)
    final screenW = Get.width;
    final screenH = Get.height;
    final topSafeArea = Get.mediaQuery.padding.top;
    const topBarHeight = 60.0;
    const bottomToolsHeight = 80.0;
    final keyboardInset = Get.mediaQuery.viewInsets.bottom;
    final playgroundHeight =
        screenH - topSafeArea - topBarHeight - bottomToolsHeight;
    final dx = (screenW - width) / 2;
    double dy = (playgroundHeight - height) / 2;
    // Eğer klavye açıksa, metni görünür alana (klavyenin üstüne) yaklaştır
    if (keyboardInset > 0) {
      final visiblePlaygroundHeight =
          (playgroundHeight - keyboardInset).clamp(120.0, playgroundHeight);
      dy = (visiblePlaygroundHeight - height) / 2;
    }
    elements.add(
      StoryElement(
        type: StoryElementType.text,
        content: text,
        width: width,
        height: height,
        position: Offset(dx, dy),
        rotation: 0,
        zIndex: ++_zIndexCounter,
        fontSize: 28, // bir tık daha büyük başlangıç
        aspectRatio: double.parse((width / height).toStringAsFixed(4)),
        textColor: textColor,
        textBgColor: textBgColor,
        hasTextBg: hasTextBg,
        textAlign: textAlign,
        fontWeight: fontWeight,
        italic: italic,
        underline: underline,
        shadowBlur: shadowBlur,
        shadowOpacity: shadowOpacity,
      ),
    );
  }

  void editTextElement({
    required StoryElement element,
    required String text,
    required int textColor,
    required int textBgColor,
    required bool hasTextBg,
    required String textAlign,
    required String fontWeight,
    bool? italic,
    bool? underline,
    double? shadowBlur,
    double? shadowOpacity,
  }) {
    _saveState();
    element.content = text;
    element.textColor = textColor;
    element.textBgColor = textBgColor;
    element.hasTextBg = hasTextBg;
    element.textAlign = textAlign;
    element.fontWeight = fontWeight;
    if (italic != null) element.italic = italic;
    if (underline != null) element.underline = underline;
    if (shadowBlur != null) element.shadowBlur = shadowBlur;
    if (shadowOpacity != null) element.shadowOpacity = shadowOpacity;
    elements.refresh();
  }

  void openDrawing() {
    Get.to<String>(
      () => DrawingScreen(onSave: (path) {
        _saveState();
        const size = 300.0;
        elements.add(
          StoryElement(
            type: StoryElementType.drawing,
            content: path,
            width: size,
            height: size,
            position: Offset(100, 100),
            rotation: 0,
            zIndex: ++_zIndexCounter,
            aspectRatio: 1.0, // Drawing is square
          ),
        );
      }),
    );
  }

  // Çağrıldığında ekranı hemen kapatır, ardından arka planda kaydeder
  void onSaveStoryPressed() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackbar("Hata", "Oturum açılmış kullanıcı yok");
      return;
    }

    // Elements kontrolü
    if (elements.isEmpty) {
      AppSnackbar("Hata", "Hikayeye en az bir element ekleyin");
      return;
    }
    // Upload öncesi snapshot al (onClose temizliklerinden etkilenmemek için)
    final elementsSnapshot = List<StoryElement>.from(elements);
    final musicSnapshot = music.value;
    final colorSnapshot = color.value;

    // Upload state'i başlat
    isUploadingStory.value = true;

    // Ekranı kapat (kullanıcıyı bekletme)
    Get.back();

    // Arka planda snapshot verileri ile devam et
    _saveStoryBackground(user, elementsSnapshot, colorSnapshot, musicSnapshot);
  }

  Future<void> _saveStoryBackground(
    User user,
    List<StoryElement> elementsSnapshot,
    Color colorSnapshot,
    String musicSnapshot,
  ) async {
    try {
      // 1) Doküman referansı
      final docRef = FirebaseFirestore.instance.collection('Stories').doc();
      final storyId = docRef.id;

      // 2) Elements'i snapshot'tan kullan
      final elementsCopy = List<StoryElement>.from(elementsSnapshot);

      if (elementsCopy.isEmpty) {
        AppSnackbar("Hata", "Hikayeye en az bir element ekleyin");
        return;
      }

      // 3) Element'leri upload & map'e çevir
      final List<Map<String, dynamic>> serialized = [];
      for (final e in elementsCopy) {
        String url = e.content;
        if (e.type == StoryElementType.image ||
            e.type == StoryElementType.video ||
            e.type == StoryElementType.drawing) {
          final file = File(e.content);
          if (!file.existsSync()) {
            print("File not found: ${e.content}");
            continue; // Skip missing files
          }
          final ext = path.extension(file.path);
          final ts = DateTime.now().millisecondsSinceEpoch;
          final uid = user.uid;
          final ref =
              FirebaseStorage.instance.ref('Stories/$uid/$storyId/$ts$ext');
          final task = await ref.putFile(file);
          url = CdnUrlBuilder.toCdnUrl(await task.ref.getDownloadURL());
        }
        serialized.add({
          'type': e.type.toString().split('.').last,
          'content': url,
          'width': e.width,
          'height': e.height,
          'position': {'x': e.position.dx, 'y': e.position.dy},
          'rotation': e.rotation,
          'zIndex': e.zIndex,
          'isMuted': e.isMuted,
          'fontSize': e.fontSize,
          'aspectRatio': e.aspectRatio, // aspectRatio'yu da kaydet
          'textColor': e.textColor,
          'textBgColor': e.textBgColor,
          'hasTextBg': e.hasTextBg,
          'textAlign': e.textAlign,
          'fontWeight': e.fontWeight,
          'italic': e.italic,
          'underline': e.underline,
          'shadowBlur': e.shadowBlur,
          'shadowOpacity': e.shadowOpacity,
        });
      }

      // 4) Serialized data kontrolü
      if (serialized.isEmpty) {
        AppSnackbar("Hata", "Hiçbir element kaydedilemedi");
        return;
      }

      // 5) Firestore'a yaz
      await docRef.set({
        'userId': user.uid,
        'createdAt': Timestamp.now().millisecondsSinceEpoch,
        'backgroundColor': colorSnapshot.value,
        'musicUrl': musicSnapshot,
        'elements': serialized,
        'deleted': false,
        'deletedAt': 0,
      });

      // 6) Audio player'ı güvenli şekilde durdur
      try {
        if (_audioPlayer.state != PlayerState.disposed) {
          await _audioPlayer.stop();
        }
      } catch (e) {
        print("AudioPlayer stop error (ignored): $e");
      }

      // 7) Başarılı mesajı (arka planda)
      // AppSnackbar("Başarılı", "Hikaye kaydedildi");
      print("Story kaydedildi: $storyId (${serialized.length} element)");

      // 8) UI'ı güncelle - global refresh çağır
      try {
        await Get.find<StoryRowController>().loadStories();
        final usr = Get.find<FirebaseMyStore>();
        usr.hasStoryOwner();
      } catch (e) {
        print("UI update error: $e");
        // UI güncelleme hatası önemli değil, story zaten kaydedildi
      }
    } catch (err) {
      AppSnackbar("Hata", "Hikaye kaydedilemedi: ${err.toString()}");
      print("saveStory error: $err");
    } finally {
      // Her durumda upload state'i temizle
      isUploadingStory.value = false;
    }
  }
}
