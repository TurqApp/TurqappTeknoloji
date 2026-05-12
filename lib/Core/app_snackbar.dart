import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/root_navigator_key.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

part 'app_snackbar_view_part.dart';
part 'app_snackbar_text_part.dart';

String? _lastSnackbarSignature;
DateTime? _lastSnackbarAt;
const Duration _snackbarDedupWindow = Duration(milliseconds: 1200);
const Duration _snackbarOverlayRetryDelay = Duration(milliseconds: 120);
const int _snackbarOverlayMaxRetry = 25;
OverlayEntry? _activeSnackbarEntry;
Timer? _activeSnackbarTimer;
_AppSnackbarRequest? _pendingSnackbarRequest;
bool _snackbarPostFrameScheduled = false;
int _snackbarSerial = 0;

Map<String, dynamic> readLastSnackbarDebugState() {
  return <String, dynamic>{
    'signature': _lastSnackbarSignature ?? '',
    'timestampMs': _lastSnackbarAt?.millisecondsSinceEpoch ?? 0,
  };
}

void clearLastSnackbarDebugState() {
  _lastSnackbarSignature = null;
  _lastSnackbarAt = null;
}

class _AppSnackbarPalette {
  final Color background;
  final Color border;
  final Color iconBadge;
  final Color text;
  final IconData icon;

  const _AppSnackbarPalette({
    required this.background,
    required this.border,
    required this.iconBadge,
    required this.text,
    required this.icon,
  });
}

class _AppSnackbarRequest {
  final String title;
  final String message;
  final Color? backgroundColor;
  final Duration duration;
  final SnackPosition snackPosition;
  final EdgeInsets margin;
  final double borderRadius;
  final Widget? icon;
  final _AppSnackbarPalette palette;
  final TextStyle titleStyle;
  final TextStyle messageStyle;
  final int maxLines;

  const _AppSnackbarRequest({
    required this.title,
    required this.message,
    required this.backgroundColor,
    required this.duration,
    required this.snackPosition,
    required this.margin,
    required this.borderRadius,
    required this.icon,
    required this.palette,
    required this.titleStyle,
    required this.messageStyle,
    required this.maxLines,
  });
}
