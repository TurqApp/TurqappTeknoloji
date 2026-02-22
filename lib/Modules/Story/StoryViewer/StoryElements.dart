import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../StoryMaker/StoryMakerController.dart';

class StoryImageWidget extends StatelessWidget {
  final StoryElement element;

  const StoryImageWidget({super.key, required this.element});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: element.position.dx,
      top: element.position.dy,
      width: element.width,
      height: element.height,
      child: Transform.rotate(
        angle: element.rotation,
        child: CachedNetworkImage(
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 100),
          imageUrl: element.content,
          fit: BoxFit.contain, // Cover yerine contain - aspect ratio korunur
          placeholder: (context, url) => Container(
            color: Colors.grey.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey.withOpacity(0.3),
            child: const Icon(Icons.error, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class StoryGifWidget extends StatelessWidget {
  final StoryElement element;
  const StoryGifWidget({required this.element, super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: element.position.dx,
      top: element.position.dy,
      width: element.width,
      height: element.height,
      child: Transform.rotate(
        angle: element.rotation,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            fadeInDuration: const Duration(milliseconds: 300),
            fadeOutDuration: const Duration(milliseconds: 100),
            imageUrl: element.content,
            fit: BoxFit.contain, // Cover yerine contain - aspect ratio korunur
            placeholder: (context, url) => Container(
              color: Colors.grey.withOpacity(0.3),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                    SizedBox(height: 8),
                    Text("GIF",
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey.withOpacity(0.3),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(height: 4),
                    Text("GIF yüklenemedi",
                        style: TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StoryTextWidget extends StatelessWidget {
  final StoryElement element;
  const StoryTextWidget({required this.element, super.key});

  @override
  Widget build(BuildContext context) {
    final align = () {
      switch (element.textAlign) {
        case 'left':
          return TextAlign.left;
        case 'right':
          return TextAlign.right;
        case 'center':
        default:
          return TextAlign.center;
      }
    }();
    final fw = element.fontWeight == 'bold' ? FontWeight.bold : FontWeight.w500;
    final fs = element.italic ? FontStyle.italic : FontStyle.normal;
    final deco = element.underline ? TextDecoration.underline : TextDecoration.none;
    return Positioned(
      left: element.position.dx,
      top: element.position.dy,
      width: element.width,
      height: element.height,
      child: Transform.rotate(
        angle: element.rotation,
        child: Container(
          width: element.width,
          height: element.height,
          alignment: Alignment.center,
          decoration: element.hasTextBg
              ? BoxDecoration(
                  color: Color(element.textBgColor),
                  borderRadius: BorderRadius.circular(10),
                )
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            element.content,
            textAlign: align,
            style: TextStyle(
              color: Color(element.textColor),
              fontSize: element.fontSize,
              fontWeight: fw,
              fontStyle: fs,
              decoration: deco,
              fontFamily: "MontserratMedium",
              height: 1.2,
              shadows: !element.hasTextBg
                  ? [
                      Shadow(
                        blurRadius: element.shadowBlur,
                        color: Colors.black
                            .withOpacity(element.shadowOpacity),
                        offset: const Offset(1, 1),
                      ),
                    ]
                  : null,
            ),
            maxLines: null,
            overflow: TextOverflow.visible,
          ),
        ),
      ),
    );
  }
}
