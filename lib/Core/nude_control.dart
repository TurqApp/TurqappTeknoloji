import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';

Future<bool> _isNsfwImage(File file, NsfwDetector detector) async {
  // 1) Dosyayı byte listesi olarak oku
  final bytes = await file.readAsBytes();
  // 2) image paketiyle decode et (PNG, JPEG, vs. hepsini okuyabiliyor)
  final original = img.decodeImage(bytes);
  if (original == null) throw Exception('Unsupported image format');
  // 3) JPEG’e encode et
  final jpgBytes = img.encodeJpg(original);
  // 4) Geçici bir file’a yaz
  final dir = await getTemporaryDirectory();
  final tmp = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
  await tmp.writeAsBytes(jpgBytes, flush: true);
  // 5) NSFW tespitine bu yeni JPEG dosyasını ver
  final result = await detector.detectNSFWFromFile(tmp);
  // 6) Geçiciyi sil
  await tmp.delete();
  return result?.isNsfw == true;
}

Future<void> checkImagesForNude({
  required List<File> resimler,
  required void Function(bool nudeVarMi) callback,
  double threshold = 0.3,
}) async {
  final detector = await NsfwDetector.load(threshold: threshold);
  bool nudeVar = false;

  for (final dosya in resimler) {
    try {
      if (await _isNsfwImage(dosya, detector)) {
        nudeVar = true;
        break;
      }
    } catch (_) {
      // Eğer bir dosya okunamazsa, atla veya kullanıcıya bildir
    }
  }
  callback(nudeVar);
}
