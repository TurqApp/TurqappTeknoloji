import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import '../../Services/current_user_service.dart';
import 'Comments/post_comments.dart';

part 'post_controller_actions_part.dart';
part 'post_controller_class_part.dart';
