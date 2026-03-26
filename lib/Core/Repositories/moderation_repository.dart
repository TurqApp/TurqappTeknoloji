import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

part 'moderation_repository_class_part.dart';

class ModerationFlaggedPost {
  final String id;
  final Map<String, dynamic> data;

  const ModerationFlaggedPost({
    required this.id,
    required this.data,
  });
}
