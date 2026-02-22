# 📦 HLS Player - Adım Adım Kurulum Kılavuzu

Bu kılavuz, HLS Video Player modülünün projenize entegrasyonu için gerekli tüm adımları içerir.

## ✅ Kurulum Kontrolü

Aşağıdaki dosyaların doğru konumlarda olduğunu kontrol edin:

### iOS Dosyaları
```
✅ ios/Runner/HLSPlayerView.swift
✅ ios/Runner/HLSPlayerFactory.swift
✅ ios/Runner/HLSPlayerPlugin.swift
✅ ios/Runner/AppDelegate.swift (güncellenmiş)
```

### Flutter Dosyaları
```
✅ lib/hls_player/hls_controller.dart
✅ lib/hls_player/hls_player.dart
✅ lib/hls_player/hls_player_example.dart
✅ lib/hls_player/README.md
✅ lib/hls_player/KURULUM.md (bu dosya)
```

## 🔧 Adım 1: iOS Xcode Projesi Yapılandırması

### 1.1. Xcode'u Açın
```bash
cd /Users/turqapp2/Desktop/turqappv2-main
open ios/Runner.xcworkspace
```

### 1.2. Swift Dosyalarını Projeye Ekleyin

1. Xcode'da sol panelde `Runner` klasörüne sağ tıklayın
2. "Add Files to Runner..." seçin
3. Aşağıdaki dosyaları seçin:
   - `HLSPlayerView.swift`
   - `HLSPlayerFactory.swift`
   - `HLSPlayerPlugin.swift`
4. **ÖNEMLİ:** "Copy items if needed" seçeneğini **KALDIRIN** (dosyalar zaten doğru konumda)
5. "Add to targets" kısmında **Runner**'ın seçili olduğundan emin olun
6. "Add" butonuna tıklayın

### 1.3. Bridging Header Kontrolü

Xcode otomatik olarak Bridging Header oluşturacaktır. Eğer sormadıysa:

1. `Runner-Bridging-Header.h` dosyasını açın
2. Aşağıdaki satırları ekleyin (genellikle boş olabilir):

```objc
// Runner-Bridging-Header.h
#import "GeneratedPluginRegistrant.h"
```

### 1.4. Build Settings Kontrolü

1. Xcode'da `Runner` target'ını seçin
2. "Build Settings" sekmesine gidin
3. "Swift Compiler - General" bölümünde:
   - **Objective-C Bridging Header:** `Runner/Runner-Bridging-Header.h`
   - **Swift Language Version:** Swift 5

## 🛠️ Adım 2: Flutter Clean & Build

### 2.1. Flutter Clean
```bash
cd /Users/turqapp2/Desktop/turqappv2-main
flutter clean
```

### 2.2. Pub Get
```bash
flutter pub get
```

### 2.3. iOS Pod Install
```bash
cd ios
pod install
cd ..
```

### 2.4. iOS Build
```bash
flutter build ios --debug
```

## 📱 Adım 3: Örnek Kullanım Ekleme

### 3.1. Main.dart'a Route Ekleyin

`lib/main.dart` dosyanıza örnek sayfayı ekleyin:

```dart
import 'package:turqappv2/hls_player/hls_player_example.dart';

// Örneğin bir buton ile:
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HLSPlayerExample(),
      ),
    );
  },
  child: const Text('HLS Video Player Test'),
)
```

### 3.2. Doğrudan Kullanım

Kendi sayfanızda kullanmak için:

```dart
import 'package:turqappv2/hls_player/hls_player.dart';
import 'package:turqappv2/hls_player/hls_controller.dart';

class MyVideoPage extends StatefulWidget {
  const MyVideoPage({super.key});

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
      appBar: AppBar(title: const Text('Video')),
      body: HLSPlayer(
        url: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
        controller: _controller,
        autoPlay: true,
        showControls: true,
      ),
    );
  }
}
```

## 🧪 Adım 4: Test Etme

### 4.1. Simülatör Test
```bash
flutter run -d "iPhone 15 Pro"
```

### 4.2. Fiziksel Cihaz Test
```bash
# Cihazları listele
flutter devices

# Cihazda çalıştır
flutter run -d [device-id]
```

### 4.3. Test URL'leri

Aşağıdaki ücretsiz HLS URL'lerini test için kullanabilirsiniz:

```dart
// Apple Test Stream
'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8'

// Tears of Steel
'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8'

// Big Buck Bunny
'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8'

// Sintel
'https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8'
```

## 🐛 Sorun Giderme

### Hata: "Module not found"

**Çözüm:**
```bash
flutter clean
rm -rf ios/Pods
rm ios/Podfile.lock
cd ios
pod install
cd ..
flutter run
```

### Hata: "Undefined symbol: _OBJC_CLASS_$_HLSPlayerPlugin"

**Çözüm:**
1. Xcode'da Build Phases > Compile Sources bölümüne gidin
2. Tüm Swift dosyalarının (`HLSPlayerView.swift`, `HLSPlayerFactory.swift`, `HLSPlayerPlugin.swift`) listede olduğunu kontrol edin
3. Yoksa "+" ile ekleyin

### Hata: "Bridging header not found"

**Çözüm:**
1. Xcode Build Settings > Swift Compiler > Objective-C Bridging Header
2. Değerin `Runner/Runner-Bridging-Header.h` olduğunu kontrol edin

### Hata: "Could not find UiKitView"

**Çözüm:**
- Bu normal bir iOS davranışıdır
- Simülatör yerine **fiziksel cihaz**da test edin
- veya Xcode'da çalıştırın

### Hata: "Event channel not initialized"

**Çözüm:**
```dart
// Controller'ı initialize ettiğinizden emin olun
final controller = HLSController();

// Widget oluşturduktan SONRA initialize edilecektir
// Manuel initialize gerekmiyor
```

### Video Oynatmıyor

**Kontrol Listesi:**
1. ✅ URL'nin geçerli bir .m3u8 dosyası olduğunu kontrol edin
2. ✅ İnternet bağlantısını kontrol edin
3. ✅ Info.plist'te NSAppTransportSecurity ayarını kontrol edin
4. ✅ Controller'ın dispose edilmediğinden emin olun
5. ✅ autoPlay: true olduğunu kontrol edin

## 📊 Build Sonrası Kontrol

### Başarılı Build Çıktısı

```
✓ Built build/ios/iphoneos/Runner.app
Flutter run key commands.
r Hot reload.
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).
```

### Xcode Konsolunda Görmek

1. Xcode'u açın
2. `Runner.xcworkspace` dosyasını açın
3. Product > Run (⌘R)
4. Console penceresinde logları izleyin

## 🎯 Production Build

### App Store için Build

```bash
# Release build
flutter build ios --release

# Archive
# Xcode > Product > Archive
# Organizer > Upload to App Store
```

### Önemli Kontroller

1. ✅ Info.plist'te tüm permission'lar ekli
2. ✅ Signing & Capabilities ayarları yapılmış
3. ✅ Version ve Build Number güncel
4. ✅ Swift dosyaları target'a eklenmiş

## 📝 Ek Notlar

### Background Audio (İsteğe Bağlı)

Arka planda ses devam etsin isterseniz:

1. Xcode'da Runner target > Signing & Capabilities
2. "+" > Background Modes
3. "Audio, AirPlay, and Picture in Picture" seçeneğini işaretleyin

veya `Info.plist`'e ekleyin:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>remote-notification</string>
    <string>fetch</string>
</array>
```

### Picture in Picture (İsteğe Bağlı)

PiP özelliği eklemek için `HLSPlayerView.swift` dosyasında:

```swift
import AVKit

var pipController: AVPictureInPictureController?

// Setup
if AVPictureInPictureController.isPictureInPictureSupported() {
    pipController = AVPictureInPictureController(playerLayer: playerLayer)
}
```

## ✅ Kurulum Tamamlandı!

Tebrikler! HLS Video Player başarıyla projenize entegre edildi.

### Sonraki Adımlar

1. 📖 `README.md` dosyasını okuyun - detaylı kullanım örnekleri
2. 🧪 `hls_player_example.dart` dosyasını çalıştırın
3. 🎨 UI kontrollerini özelleştirin
4. 🚀 Kendi videolarınızı test edin

### Yardım

Sorun yaşarsanız:
- Debug loglarını kontrol edin (Flutter & Xcode console)
- README.md'deki sorun giderme bölümüne bakın
- iOS ve Flutter versiyonlarını kontrol edin

---

**Kurulum Tarihi:** 2026-02-16
**Platform:** iOS (Native AVPlayer)
**Flutter SDK:** >=3.3.0
