import 'dart:io';
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:svg_flutter/svg.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'cached_user_avatar_state_part.dart';
part 'cached_user_avatar_support_part.dart';

class CachedUserAvatar extends StatefulWidget {
  final String? userId;
  final double radius;
  final String? imageUrl;
  final Color? backgroundColor;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedUserAvatar({
    super.key,
    this.userId,
    this.radius = 20,
    this.imageUrl,
    this.backgroundColor,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<CachedUserAvatar> createState() => _CachedUserAvatarState();
}
