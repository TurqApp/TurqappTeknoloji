import 'dart:async';

import 'package:flutter/material.dart';

Future<Size> getImageSize(String imageUrl) async {
  final Completer<Size> completer = Completer();
  final Image image = Image.network(imageUrl);

  image.image.resolve(const ImageConfiguration()).addListener(
    ImageStreamListener((ImageInfo info, bool _) {
      final Size mySize = Size(
        info.image.width.toDouble(),
        info.image.height.toDouble(),
      );
      completer.complete(mySize);
    }),
  );

  return completer.future;
}
