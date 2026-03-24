import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Core/rozet_content.dart';

class PasajOwnerCard extends StatelessWidget {
  const PasajOwnerCard({
    super.key,
    required this.title,
    required this.userId,
    this.subtitle,
    this.imageUrl,
    this.onTap,
    this.showChevron = true,
  });

  final String title;
  final String userId;
  final String? subtitle;
  final String? imageUrl;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final trimmedTitle = title.trim();
    final trimmedSubtitle = subtitle?.trim() ?? '';
    final canOpen = onTap != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF6F7FB),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            CachedUserAvatar(
              userId: userId.isEmpty ? null : userId,
              imageUrl: imageUrl,
              radius: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          trimmedTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                      ),
                      if (userId.isNotEmpty)
                        RozetContent(
                          size: 14,
                          userID: userId,
                          leftSpacing: 1,
                        ),
                    ],
                  ),
                  if (trimmedSubtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      trimmedSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showChevron && canOpen)
              const Icon(
                CupertinoIcons.chevron_right,
                color: Colors.black38,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
