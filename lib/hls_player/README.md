# 🎬 HLS Video Player - Native iOS AVPlayer with Flutter

Production-ready HLS (HTTP Live Streaming) video player oluşturulmuştur. Native iOS AVPlayer kullanarak yüksek performanslı video oynatma özellikleri sunulur.

## ✨ Özellikler

- ✅ **Native iOS AVPlayer** ile tam performanslı oynatma
- ✅ **HLS (.m3u8)** desteği ve adaptive bitrate streaming
- ✅ **Segment bazlı** video yükleme (.ts, .m4s)
- ✅ **Auto play** ve **loop** desteği
- ✅ **Play/Pause/Seek** kontrolleri
- ✅ **Mute/Unmute** ve volume kontrolü
- ✅ **Buffering state** takibi
- ✅ **Real-time position** ve duration güncellemeleri
- ✅ **Event-driven** mimari (EventChannel)
- ✅ **Memory-safe** lifecycle yönetimi
- ✅ **Background/Foreground** app state yönetimi
- ✅ **Custom UI controls** widget
- ✅ **Error handling** ve retry mekanizması

## 📦 Kurulum

### 1. iOS Dosyaları

Aşağıdaki dosyalar `ios/Runner/` dizinine eklenmiştir:

```
ios/Runner/
├── HLSPlayerView.swift       # AVPlayer view implementasyonu
├── HLSPlayerFactory.swift    # PlatformView factory
└── HLSPlayerPlugin.swift     # MethodChannel plugin
```

### 2. AppDelegate Kaydı

`ios/Runner/AppDelegate.swift` dosyasına plugin kaydı eklenmiştir:

```swift
// Register HLS Player Plugin
if let hlsRegistrar = self.registrar(forPlugin: "HLSPlayerPlugin") {
  HLSPlayerPlugin.register(with: hlsRegistrar)
}
```

### 3. Info.plist İzinleri

`ios/Runner/Info.plist` dosyasında network izinleri zaten mevcut:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### 4. Flutter Dosyaları

Flutter tarafında aşağıdaki dosyalar oluşturulmuştur:

```
lib/hls_player/
├── hls_controller.dart         # Video controller (state management)
├── hls_player.dart             # Player widget (PlatformView)
├── hls_player_example.dart     # Örnek kullanım sayfası
└── README.md                   # Bu dosya
```

## 🚀 Kullanım

### Basit Kullanım

```dart
import 'package:turqappv2/hls_player/hls_player.dart';
import 'package:turqappv2/hls_player/hls_controller.dart';

class MyVideoPage extends StatefulWidget {
  @override
  State<MyVideoPage> createState() => _MyVideoPageState();
}

class _MyVideoPageState extends State<MyVideoPage> {
  late HLSController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HLSController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Player')),
      body: HLSPlayer(
        url: 'https://example.com/video.m3u8',
        controller: _controller,
        autoPlay: true,
        loop: false,
        showControls: true,
        aspectRatio: 16 / 9,
      ),
    );
  }
}
```

### Gelişmiş Kullanım

```dart
class AdvancedVideoPage extends StatefulWidget {
  @override
  State<AdvancedVideoPage> createState() => _AdvancedVideoPageState();
}

class _AdvancedVideoPageState extends State<AdvancedVideoPage> {
  late HLSController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HLSController();

    // State değişikliklerini dinle
    _controller.onStateChanged.listen((state) {
      print('Player State: $state');
    });

    // Hataları dinle
    _controller.onError.listen((error) {
      print('Error: $error');
      // Hata UI göster
    });

    // Position değişikliklerini dinle
    _controller.onPositionChanged.listen((position) {
      print('Position: ${position.inSeconds}s');
    });

    // Buffering durumunu dinle
    _controller.onBufferingChanged.listen((isBuffering) {
      print('Buffering: $isBuffering');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Video Player
          HLSPlayer(
            url: 'https://example.com/video.m3u8',
            controller: _controller,
            autoPlay: true,
            loop: false,
            showControls: true,
            aspectRatio: 16 / 9,
            backgroundColor: Colors.black,
            loadingWidget: CircularProgressIndicator(),
            errorWidget: Text('Video yüklenemedi'),
          ),

          // Custom Kontroller
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.play_arrow),
                onPressed: () => _controller.play(),
              ),
              IconButton(
                icon: Icon(Icons.pause),
                onPressed: () => _controller.pause(),
              ),
              IconButton(
                icon: Icon(Icons.replay),
                onPressed: () => _controller.seekTo(0),
              ),
              IconButton(
                icon: Icon(_controller.isMuted
                  ? Icons.volume_off
                  : Icons.volume_up),
                onPressed: () => _controller.setMuted(!_controller.isMuted),
              ),
            ],
          ),

          // Player Info
          StreamBuilder<PlayerState>(
            stream: _controller.onStateChanged,
            builder: (context, snapshot) {
              return Text('State: ${snapshot.data}');
            },
          ),

          StreamBuilder<Duration>(
            stream: _controller.onPositionChanged,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              return Text('Position: ${position.inSeconds}s');
            },
          ),
        ],
      ),
    );
  }
}
```

### Controller Metodları

```dart
// Video yükleme
await controller.loadVideo(
  'https://example.com/video.m3u8',
  autoPlay: true,
  loop: false,
);

// Oynatma kontrolü
await controller.play();
await controller.pause();
await controller.togglePlayPause();

// Seek (saniye cinsinden)
await controller.seekTo(30.0);

// Ses kontrolü
await controller.setMuted(true);
await controller.setVolume(0.5); // 0.0 - 1.0

// Loop ayarı
await controller.setLoop(true);

// Bilgi alma
double currentTime = await controller.getCurrentTime();
double duration = await controller.getDuration();
bool isMuted = controller.isMuted;
bool isPlaying = controller.isPlaying;
PlayerState state = controller.state;

// Dispose
await controller.dispose();
```

### State Management

```dart
// PlayerState enum değerleri
enum PlayerState {
  idle,       // Başlangıç durumu
  loading,    // Video yükleniyor
  ready,      // Video hazır
  playing,    // Oynatılıyor
  paused,     // Duraklatıldı
  buffering,  // Tamponlanıyor
  completed,  // Tamamlandı
  error,      // Hata oluştu
}

// State dinleme
controller.onStateChanged.listen((state) {
  switch (state) {
    case PlayerState.loading:
      // Loading UI göster
      break;
    case PlayerState.playing:
      // Play icon güncelle
      break;
    case PlayerState.error:
      // Hata mesajı göster
      print(controller.errorMessage);
      break;
    // ...
  }
});
```

## 📱 Örnek Uygulama

Örnek kullanım için `hls_player_example.dart` dosyasını inceleyin:

```dart
import 'package:turqappv2/hls_player/hls_player_example.dart';

// Ana uygulamada göstermek için
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => HLSPlayerExample(),
  ),
);
```

## 🔧 Teknik Detaylar

### iOS Native Katmanı

**HLSPlayerView.swift**
- AVPlayer ve AVPlayerLayer kullanımı
- KVO (Key-Value Observing) ile state takibi
- NotificationCenter ile lifecycle events
- Memory-safe cleanup ve deinit
- Background/Foreground handling

**AVPlayer Optimizasyonları**
```swift
// HLS için optimize edilmiş ayarlar
playerItem?.preferredForwardBufferDuration = 3.0
player?.automaticallyWaitsToMinimizeStalling = true

// AVURLAsset yapılandırması
let asset = AVURLAsset(url: videoURL, options: [
    AVURLAssetPreferPreciseDurationAndTimingKey: true
])
```

### Flutter Köprü Katmanı

**MethodChannel**
- Channel name: `turqapp.hls_player/method`
- Methods: loadVideo, play, pause, seek, setMuted, setVolume, setLoop, dispose

**EventChannel**
- Channel name: `turqapp.hls_player/events_{viewId}`
- Events: ready, play, pause, buffering, timeUpdate, completed, error

**PlatformView**
- View type: `turqapp.hls_player/view`
- iOS: UiKitView
- Creation params: url, autoPlay, loop

## 🎯 HLS Format Desteği

### Desteklenen Formatlar
- ✅ `.m3u8` playlist dosyaları
- ✅ `.ts` transport stream segments
- ✅ `.m4s` fragmented MP4 segments
- ✅ Adaptive bitrate streaming (ABR)
- ✅ Multiple audio/subtitle tracks
- ✅ AES-128 encryption (DRM)

### Örnek HLS URL'leri

```dart
// Basit HLS
'https://domain.com/video/master.m3u8'

// Adaptive bitrate
'https://domain.com/video/playlist.m3u8'

// Segment yapısı
// https://domain.com/video/
//   ├── master.m3u8
//   ├── 360p/
//   │   ├── playlist.m3u8
//   │   ├── segment_0.ts
//   │   ├── segment_1.ts
//   ├── 720p/
//   │   ├── playlist.m3u8
//   │   ├── segment_0.ts
//   │   ├── segment_1.ts
```

## 🐛 Hata Yönetimi

```dart
// Error stream dinleme
controller.onError.listen((error) {
  print('Video Error: $error');

  // Kullanıcıya göster
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Hata'),
      content: Text(error),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Tamam'),
        ),
      ],
    ),
  );
});

// State ile hata kontrolü
if (controller.state == PlayerState.error) {
  print('Error message: ${controller.errorMessage}');
}
```

## 📊 Performans İpuçları

1. **Buffering Optimizasyonu**
   ```dart
   // iOS tarafında otomatik optimize edilmiştir
   // preferredForwardBufferDuration = 3.0
   ```

2. **Memory Management**
   ```dart
   // Widget dispose edildiğinde mutlaka controller'ı dispose edin
   @override
   void dispose() {
     controller.dispose();
     super.dispose();
   }
   ```

3. **Background Mode**
   ```swift
   // iOS automatically pauses on background
   // Foreground'da manuel resume gerekiyorsa:
   NotificationCenter.default.addObserver(
     forName: UIApplication.willEnterForegroundNotification
   )
   ```

## 🔄 Lifecycle Yönetimi

```dart
class VideoPageWithLifecycle extends StatefulWidget {
  @override
  State<VideoPageWithLifecycle> createState() => _VideoPageWithLifecycleState();
}

class _VideoPageWithLifecycleState extends State<VideoPageWithLifecycle>
    with WidgetsBindingObserver {
  late HLSController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HLSController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller.pause();
    } else if (state == AppLifecycleState.resumed) {
      // İsterseniz otomatik devam ettirin
      // _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return HLSPlayer(
      url: 'https://example.com/video.m3u8',
      controller: _controller,
    );
  }
}
```

## 🚨 Bilinen Sınırlamalar

1. **Platform Desteği**
   - Şu anda sadece iOS desteklenmektedir
   - Android için farklı implementasyon gerekir (ExoPlayer)

2. **Background Audio**
   - Info.plist'te background audio mode eklenmemiştir
   - Gerekirse `UIBackgroundModes` array'ine `audio` ekleyin

3. **Picture-in-Picture (PiP)**
   - Şu anda PiP desteği yoktur
   - İhtiyaç halinde AVPictureInPictureController eklenebilir

## 📝 Changelog

### v1.0.0 (2026-02-16)
- ✅ İlk production-ready release
- ✅ iOS AVPlayer implementasyonu
- ✅ HLS streaming desteği
- ✅ Full MethodChannel & EventChannel köprüsü
- ✅ Custom UI controls
- ✅ Lifecycle management
- ✅ Error handling
- ✅ Memory-safe cleanup

## 👨‍💻 Geliştirici Notları

### Debug Modu
```dart
// iOS tarafında debug logları için
// HLSPlayerView.swift içinde:
// print("[HLSPlayer] ...")
```

### Event İzleme
```dart
// Tüm eventleri takip etmek için
controller.onStateChanged.listen((state) => print('State: $state'));
controller.onPositionChanged.listen((pos) => print('Position: $pos'));
controller.onDurationChanged.listen((dur) => print('Duration: $dur'));
controller.onBufferingChanged.listen((buf) => print('Buffering: $buf'));
controller.onError.listen((err) => print('Error: $err'));
```

## 📄 Lisans

Bu kod projenizin bir parçasıdır ve projenizin lisansına tabidir.

## 🤝 Destek

Sorularınız veya sorunlarınız için:
- README dosyasını kontrol edin
- Example uygulamayı inceleyin
- iOS ve Flutter debug loglarını kontrol edin

---

**Hazırlayan:** Claude AI
**Tarih:** 2026-02-16
**Versiyon:** 1.0.0
