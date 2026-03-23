import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

part 'app_snackbar_view_part.dart';
part 'app_snackbar_text_part.dart';

String? _lastSnackbarSignature;
DateTime? _lastSnackbarAt;
const Duration _snackbarDedupWindow = Duration(milliseconds: 1200);

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
