import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/SocialProfile/SocialProfile.dart';
import 'package:turqappv2/Services/ReshareHelper.dart';

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
  String? _nickname;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNickname();
  }

  @override
  void didUpdateWidget(SharedPostLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.originalUserID != widget.originalUserID) {
      _loadNickname();
    }
  }

  void _loadNickname() async {
    if (widget.originalUserID.isEmpty) {
      return;
    }

    // Önce cache'ten kontrol et
    final cachedNickname =
        ReshareHelper.getCachedNickname(widget.originalUserID);

    if (cachedNickname != null) {
      // Cache'te var, direkt kullan
      if (mounted) {
        setState(() {
          _nickname = cachedNickname;
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
          final nickname =
              await ReshareHelper.getUserNickname(widget.originalUserID);
          if (mounted) {
            setState(() {
              _nickname = nickname;
              _isLoading = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _nickname = 'Bilinmeyen Kullanıcı';
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
    if (_nickname == null && !_isLoading) {
      return const SizedBox.shrink();
    }

    // Nickname varsa göster
    if (_nickname != null) {
      return GestureDetector(
        onTap: () {
          // Kendi ID'si ise tıklanabilir olmasın
          final currentUserID = FirebaseAuth.instance.currentUser?.uid;
          if (widget.originalUserID != currentUserID) {
            Get.to(() => SocialProfile(userID: widget.originalUserID));
          }
        },
        child: Text(
          'Kimden: @$_nickname',
          style: TextStyle(
            color: widget.textColor,
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
