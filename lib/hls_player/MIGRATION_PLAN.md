# 🔄 PLAYER MİGRATION PLANI

**Hedef:** Tek player mimarisi - HLS Player her yerde kullanılacak

---

## 1️⃣ MEVCUT DURUM

### Eski Player (TurqNativeAVPlayer)
```
Konum: AppDelegate.swift (satır 28-382)
Kullanım: StoryVideoWidget.dart
Channel: turqapp/av_player_{viewId}
Format: MP4, MOV, HLS (genel)
```

### Yeni Player (HLSPlayer)
```
Konum: HLSPlayerView.swift
Kullanım: Henüz yok (sadece test)
Channel: turqapp.hls_player
Format: HLS optimize (ama her format çalışır)
```

---

## 2️⃣ MİGRATION ADIMLARI

### Adım 1: HLS Player'ı Generic Yap

**Dosya:** `HLSPlayerView.swift`

**Değişiklik:** URL kontrolünü genişlet

```swift
// Önce:
func loadVideo(url: String) {
    // Sadece HLS için optimize edilmiş
}

// Sonra:
func loadVideo(url: String) {
    // Her format için çalışır (MP4, MOV, HLS)
    // AVPlayer zaten universal
}
```

**Not:** Aslında zaten çalışıyor! AVPlayer her formatı destekler.

---

### Adım 2: StoryVideoWidget Migration

**Dosya:** `lib/Modules/Story/StoryViewer/StoryVideoWidget.dart`

**Eski Kod:**
```dart
final NativeAvPlayerController _nativeController = NativeAvPlayerController();

NativeAvPlayerView(
  controller: _nativeController,
  url: widget.element.content,
  paused: _effectivePaused,
  muted: widget.element.isMuted,
  onReady: _onNativeReady,
  onEnded: _onNativeEnded,
)
```

**Yeni Kod:**
```dart
final HLSController _hlsController = HLSController();

HLSPlayer(
  controller: _hlsController,
  url: widget.element.content,
  autoPlay: !_effectivePaused,
  loop: false,
  showControls: false, // Story'de kontrol yok
)

// Event listeners:
_hlsController.onStateChanged.listen((state) {
  if (state == PlayerState.ready) {
    _onNativeReady(_hlsController.duration);
  } else if (state == PlayerState.completed) {
    _onNativeEnded();
  }
});
```

---

### Adım 3: NativeAvPlayerView.dart Silme

**Dosya:** `lib/Core/Widgets/NativeAvPlayerView.dart`

**Eylem:** Dosyayı sil (artık kullanılmıyor)

```bash
rm lib/Core/Widgets/NativeAvPlayerView.dart
```

---

### Adım 4: AppDelegate Temizleme

**Dosya:** `ios/Runner/AppDelegate.swift`

**Silinecek Satırlar:** 28-382

**Eski Kod (SİLİNECEK):**
```swift
// Satır 28-31
if let registrar = self.registrar(forPlugin: "TurqNativeAVPlayer") {
  let factory = TurqNativeAVPlayerFactory(messenger: registrar.messenger())
  registrar.register(factory, withId: "turqapp/av_player")
}

// Satır 42-382
private final class TurqNativeAVPlayerContainerView: UIView {
  ...
}
private final class TurqNativeAVPlayerFactory: NSObject, FlutterPlatformViewFactory {
  ...
}
private final class TurqNativeAVPlayerPlatformView: NSObject, FlutterPlatformView {
  ...
}
```

**Yeni Kod (SADECE HLS KALACAK):**
```swift
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("<YOUR_GOOGLE_MAPS_API_KEY>")

    // Audio session setup (GlobalHLSPlayerManager içinde yapılacak)
    // Bu kod da silinebilir

    GeneratedPluginRegistrant.register(with: self)

    // ✅ SADECE HLS PLAYER
    if let hlsRegistrar = self.registrar(forPlugin: "HLSPlayerPlugin") {
      HLSPlayerPlugin.register(with: hlsRegistrar)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
// ✅ Dosya sonu - Başka class yok
```

---

### Adım 5: Import Temizleme

**Dosya:** `lib/Modules/Story/StoryViewer/StoryVideoWidget.dart`

```dart
// Eski import (SİL)
import 'package:turqappv2/Core/Widgets/NativeAvPlayerView.dart';

// Yeni import (EKLE)
import 'package:turqappv2/hls_player/hls_player_module.dart';
```

---

## 3️⃣ GENİŞLETİLMİŞ StoryVideoWidget

Tam migration kodu:

```dart
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:turqappv2/hls_player/hls_player_module.dart'; // YENİ
import '../StoryMaker/StoryMakerController.dart';
import 'package:turqappv2/main.dart';

class StoryVideoWidget extends StatefulWidget {
  // Aynı kalıyor...
}

class _StoryVideoWidgetState extends State<StoryVideoWidget> with RouteAware {
  VideoPlayerController? _controller;
  final HLSController _hlsController = HLSController(); // YENİ

  bool _notifiedStarted = false;
  bool _notifiedEnded = false;
  bool _hlsReady = false; // YENİ
  bool _routePaused = false;
  Timer? _maxTimer;
  StreamSubscription? _hlsStateSub; // YENİ

  bool get _useNativeAVPlayer =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  bool get _effectivePaused => widget.paused || _routePaused;

  @override
  void initState() {
    super.initState();
    if (_useNativeAVPlayer) {
      // YENİ: HLS controller event listener
      _hlsStateSub = _hlsController.onStateChanged.listen((state) {
        if (!mounted) return;

        if (state == PlayerState.ready) {
          if (!_hlsReady) {
            setState(() {
              _hlsReady = true;
            });
            _onHlsReady(_hlsController.duration);
          }
        } else if (state == PlayerState.completed) {
          _onHlsEnded();
        }
      });
      return;
    }

    // Android - video_player (aynı kalıyor)
    _controller = VideoPlayerController.network(widget.element.content)
      ..initialize().then((_) {
        // Aynı kod...
      })
      ..addListener(_videoListener);
  }

  void _notifyStarted(Duration actualDuration) {
    // Aynı kod...
  }

  void _emitEnded() {
    // Aynı kod...
  }

  void _onHlsReady(double durationSeconds) {
    if (!mounted) return;
    _notifyStarted(Duration(milliseconds: (durationSeconds * 1000).toInt()));
  }

  void _onHlsEnded() {
    _emitEnded();
  }

  // --- RouteAware integration ---
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    if (_useNativeAVPlayer) {
      _hlsStateSub?.cancel(); // YENİ
      _hlsController.dispose(); // YENİ
    } else {
      _controller?.removeListener(_videoListener);
      _controller?.dispose();
    }
    _maxTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StoryVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.element.isMuted != widget.element.isMuted) {
      if (_useNativeAVPlayer) {
        _hlsController.setMuted(widget.element.isMuted); // YENİ
      } else if (_controller?.value.isInitialized == true) {
        _controller?.setVolume(widget.element.isMuted ? 0 : 1);
      }
    }
    if (oldWidget.paused != widget.paused) {
      if (_useNativeAVPlayer) {
        if (_effectivePaused) {
          _hlsController.pause(); // YENİ
        } else {
          _hlsController.play(); // YENİ
        }
      } else {
        // Android aynı...
      }
    }
  }

  @override
  void didPushNext() {
    _routePaused = true;
    if (_useNativeAVPlayer) {
      _hlsController.pause(); // YENİ
    } else if (_controller?.value.isPlaying == true) {
      _controller?.pause();
    }
  }

  @override
  void didPopNext() {
    _routePaused = false;
    if (_useNativeAVPlayer) {
      if (!_effectivePaused && !_notifiedEnded) {
        _hlsController.play(); // YENİ
      }
      return;
    }
    // Android aynı...
  }

  void pause() {
    if (_useNativeAVPlayer) {
      _hlsController.pause(); // YENİ
      return;
    }
    if (_controller?.value.isPlaying == true) {
      _controller?.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _useNativeAVPlayer
        ? Stack(
            children: [
              // YENİ: HLS Player
              HLSPlayer(
                url: widget.element.content,
                controller: _hlsController,
                autoPlay: !_effectivePaused,
                loop: false,
                showControls: false, // Story'de kontrol yok
                fit: BoxFit.contain,
                aspectRatio: widget.element.width / widget.element.height,
              ),
              if (!_hlsReady)
                const Center(
                  child: CupertinoActivityIndicator(color: Colors.grey),
                ),
            ],
          )
        : (_controller?.value.isInitialized == true
            ? FittedBox(
                // Android aynı...
              )
            : const Center(
                child: CupertinoActivityIndicator(color: Colors.grey),
              ));

    return Positioned(
      left: widget.element.position.dx,
      top: widget.element.position.dy,
      width: widget.element.width,
      height: widget.element.height,
      child: Transform.rotate(
        angle: widget.element.rotation,
        child: child,
      ),
    );
  }
}
```

---

## 4️⃣ TEST PLANI

### Test 1: Story Video Oynatma
```
1. Story açılsın
2. Video otomatik başlasın
3. Pause/resume çalışsın
4. Mute/unmute çalışsın
5. Video bitince sonraki story'ye geçsin
```

### Test 2: Memory Leak
```
1. 10 story aç/kapat
2. Instruments ile leak kontrolü
3. Memory kullanımı stabil mi?
```

### Test 3: Performance
```
1. Story swipe hızı
2. Video yükleme süresi
3. UI donması var mı?
```

---

## 5️⃣ ROLLBACK PLANI

Eğer sorun çıkarsa:

```bash
# Git ile eski versiyona dön
git checkout HEAD~1 ios/Runner/AppDelegate.swift
git checkout HEAD~1 lib/Modules/Story/StoryViewer/StoryVideoWidget.dart

# Eski player'ı geri getir
git checkout HEAD~1 lib/Core/Widgets/NativeAvPlayerView.dart

# Build
flutter clean && flutter run
```

---

## 6️⃣ TİMELINE

| Adım | Süre | Durum |
|------|------|-------|
| 1. HLS Player kontrolü | 10 dk | ⏳ Bekliyor |
| 2. StoryVideoWidget migration | 30 dk | ⏳ Bekliyor |
| 3. AppDelegate temizleme | 10 dk | ⏳ Bekliyor |
| 4. Build & Test | 20 dk | ⏳ Bekliyor |
| 5. Memory test | 15 dk | ⏳ Bekliyor |
| **TOPLAM** | **85 dk** | **~1.5 saat** |

---

## ✅ KARAR

**Hazır mısınız?**

1. ✅ **EVET** - Migration'ı başlat, dosyaları üret
2. ❌ **HAYIR** - Mevcut durumu koru (2 player)
3. ⏸️ **SONRA** - Şimdilik iki player kalsın

---

**Hazırlayan:** Claude AI
**Tarih:** 2026-02-16
**Durum:** Onay Bekliyor
