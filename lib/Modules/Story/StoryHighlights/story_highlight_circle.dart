import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'story_highlight_model.dart';

class StoryHighlightCircle extends StatelessWidget {
  final StoryHighlightModel highlight;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const StoryHighlightCircle({
    super.key,
    required this.highlight,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Center(
        child: SizedBox(
          width: 70,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.withAlpha(50)),
                ),
                padding: const EdgeInsets.all(4),
                child: ClipOval(
                  child: highlight.coverUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: highlight.coverUrl,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          placeholder: (_, __) => Container(
                            color: Colors.grey.withAlpha(30),
                            child: const Icon(
                              CupertinoIcons.collections,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey.withAlpha(30),
                            child: const Icon(
                              CupertinoIcons.collections,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey.withAlpha(30),
                          child: const Icon(
                            CupertinoIcons.collections,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                highlight.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontFamily: 'MontserratMedium',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
