import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';

Future<ui.Size> getImageSize(String imageUrl) async {
  final file = await TurqImageCacheManager.instance.getSingleFile(imageUrl);
  final bytes = await file.readAsBytes();
  return _decodeSize(bytes);
}

Future<ui.Size> _decodeSize(Uint8List bytes) async {
  final Completer<ui.Size> completer = Completer<ui.Size>();
  ui.decodeImageFromList(bytes, (ui.Image image) {
    completer.complete(
      ui.Size(image.width.toDouble(), image.height.toDouble()),
    );
  });
  return completer.future;
}
