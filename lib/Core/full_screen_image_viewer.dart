import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinch_zoom/pinch_zoom.dart';

class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  double _verticalDragDistance = 0;
  int _activePointerCount = 0;

  void _handlePointerDown(PointerDownEvent event) {
    _activePointerCount += 1;
    if (_activePointerCount == 1) {
      _verticalDragDistance = 0;
      return;
    }
    _verticalDragDistance = 0;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_activePointerCount != 1) {
      return;
    }
    _verticalDragDistance += event.delta.dy;
    if (_verticalDragDistance > 100) {
      _verticalDragDistance = 0;
      Get.back();
    }
  }

  void _handlePointerEnd(PointerEvent event) {
    if (_activePointerCount > 0) {
      _activePointerCount -= 1;
    }
    _verticalDragDistance = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: _handlePointerEnd,
        onPointerCancel: _handlePointerEnd,
        child: Stack(
          children: [
            Center(
              child: PinchZoom(
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  placeholder: (context, url) => CupertinoActivityIndicator(),
                  errorWidget: (context, url, error) =>
                      Icon(Icons.error, color: Colors.red),
                ),
              ),
            ),
            Positioned(
              top: 50,
              right: 20,
              child: IconButton(
                icon: Icon(CupertinoIcons.xmark, color: Colors.black, size: 24),
                onPressed: () => Get.back(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
