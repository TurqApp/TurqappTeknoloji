import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/SocialProfile/social_profile.dart';
import 'package:turqappv2/Services/reshare_helper.dart';

class SharedPostLabel extends StatefulWidget {
  final String originalUserID;
  final Color textColor;
  final double fontSize;

  const SharedPostLabel({
    super.key,
    required this.originalUserID,
    this.textColor = Colors.grey,
    this.fontSize = 12,
  });

  @override
  State<SharedPostLabel> createState() => _SharedPostLabelState();
}

class _SharedPostLabelState extends State<SharedPostLabel> {
  String? _displayName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
  }

  @override
  void didUpdateWidget(SharedPostLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.originalUserID != widget.originalUserID) {
      _loadDisplayName();
    }
  }

  void _loadDisplayName() async {
    if (widget.originalUserID.isEmpty) {
      return;
    }

    // Önce cache'ten kontrol et
    final cachedName =
        ReshareHelper.getCachedDisplayName(widget.originalUserID);

    if (cachedName != null) {
      // Cache'te var, direkt kullan
      if (mounted) {
        setState(() {
          _displayName = cachedName;
          _isLoading = false;
        });
      }
    } else {
      // Cache'te yok, yükle (sadece bir kez)
      if (!_isLoading) {
        setState(() {
          _isLoading = true;
        });

        try {
          final displayName =
              await ReshareHelper.getUserDisplayName(widget.originalUserID);
          if (mounted) {
            setState(() {
              _displayName = displayName;
              _isLoading = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _displayName = 'Bilinmeyen Kullanıcı';
              _isLoading = false;
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Yeniden paylaşım yoksa hiçbir şey gösterme
    if (widget.originalUserID.isEmpty) {
      return const SizedBox.shrink();
    }

    // Nickname yok ve yükleniyor da değilse hiçbir şey gösterme
    if (_displayName == null && !_isLoading) {
      return const SizedBox.shrink();
    }

    // Nickname varsa göster
    if (_displayName != null) {
      return GestureDetector(
        onTap: () {
          // Kendi ID'si ise tıklanabilir olmasın
          final currentUserID = FirebaseAuth.instance.currentUser?.uid;
          if (widget.originalUserID != currentUserID) {
            Get.to(() => SocialProfile(userID: widget.originalUserID));
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Kimden $_displayName',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
