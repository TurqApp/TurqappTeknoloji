import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Models/social_media_model.dart';

class SocialMediaContent extends StatelessWidget {
  final SocialMediaModel model;

  const SocialMediaContent({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // circular icon
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
              child: CachedNetworkImage(
                imageUrl: model.logo,
                fit: BoxFit.cover,
                memCacheHeight: 300,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // title
          Text(
            model.title,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontFamily: "MontserratMedium",
            ),
          ),
        ],
      ),
    );
  }
}
