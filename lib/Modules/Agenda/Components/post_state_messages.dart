// 📁 lib/Modules/Agenda/Components/post_state_messages.dart
// 📢 Shared state message cards for hidden/archived/deleted posts
// Eliminates 180 lines of duplicate code between Modern and Classic

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Modules/Agenda/Common/agenda_spacing.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';

/// Shows "Gönderi Gizlendi" message with undo action
/// Replaces duplicate code in AgendaContent:635-696 and ClassicContent:1531-1588
class PostHiddenMessage extends StatelessWidget {
  const PostHiddenMessage({
    super.key,
    required this.onUndo,
    this.videoController,
  });

  final VoidCallback onUndo;
  final HLSVideoAdapter? videoController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AgendaSpacing.responsiveUnit(context) * 2,
            vertical: AgendaSpacing.responsiveUnit(context) * 3,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.checkmark_seal,
                color: Colors.green,
                size: 30,
              ),
              AgendaSpacing.headerToContentGap.verticalSpace,
              const Text(
                "Gönderi Gizlendi",
                style: TextStyle(
                  fontFamily: 'MontserratMedium',
                  fontSize: 15,
                ),
              ),
              (AgendaSpacing.headerToContentGap / 2).verticalSpace,
              const Text(
                "Bu gönderi gizlendi. Bunun gibi gönderileri akışında daha altlarda göreceksin.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              AgendaSpacing.contentToActionsGap.verticalSpace,
              GestureDetector(
                onTap: () {
                  onUndo();
                  videoController?.play();
                },
                child: const Text(
                  "Geri Al",
                  style: TextStyle(
                    fontFamily: 'MontserratMedium',
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(color: Colors.grey.withValues(alpha: 0.2)),
      ],
    );
  }
}

/// Shows "Gönderi Arşivlendi" message with undo action
/// Replaces duplicate code in AgendaContent:698-759 and ClassicContent:1590-1645
class PostArchivedMessage extends StatelessWidget {
  const PostArchivedMessage({
    super.key,
    required this.onUndo,
    this.videoController,
  });

  final VoidCallback onUndo;
  final HLSVideoAdapter? videoController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AgendaSpacing.responsiveUnit(context) * 2,
            vertical: AgendaSpacing.responsiveUnit(context) * 3,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.checkmark_seal,
                color: Colors.green,
                size: 30,
              ),
              AgendaSpacing.headerToContentGap.verticalSpace,
              const Text(
                "Gönderi Arşivlendi",
                style: TextStyle(
                  fontFamily: 'MontserratMedium',
                  fontSize: 15,
                ),
              ),
              (AgendaSpacing.headerToContentGap / 2).verticalSpace,
              const Text(
                "Bu gönderiyi arşivlediniz.\nArtık kimseye bu gönderi gözükmeyecektir.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              AgendaSpacing.contentToActionsGap.verticalSpace,
              GestureDetector(
                onTap: () {
                  onUndo();
                  videoController?.play();
                },
                child: const Text(
                  "Geri Al",
                  style: TextStyle(
                    fontFamily: 'MontserratMedium',
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(color: Colors.grey.withValues(alpha: 0.2)),
      ],
    );
  }
}

/// Shows "Gönderi Sildiniz" message (no undo - permanent)
/// Replaces duplicate code in AgendaContent:761-809 and ClassicContent:1647-1689
class PostDeletedMessage extends StatelessWidget {
  const PostDeletedMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AgendaSpacing.responsiveUnit(context) * 2,
            vertical: AgendaSpacing.responsiveUnit(context) * 3,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.checkmark_seal,
                color: Colors.green,
                size: 30,
              ),
              AgendaSpacing.headerToContentGap.verticalSpace,
              const Text(
                "Gönderi Sildiniz",
                style: TextStyle(
                  fontFamily: 'MontserratMedium',
                  fontSize: 15,
                ),
              ),
              (AgendaSpacing.headerToContentGap / 2).verticalSpace,
              const Text(
                "Bu gönderi artık yayında değil.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Divider(color: Colors.grey.withValues(alpha: 0.2)),
      ],
    );
  }
}
