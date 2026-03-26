import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/typesense_post_service.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/Profile/MyProfile/profile_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/hls_player/hls_video_adapter.dart';
import 'package:uuid/uuid.dart';

import '../../../Core/Helpers/GlobalLoader/global_loader_controller.dart';
import '../../../Core/LocationFinderView/location_finder_view.dart';

part 'url_post_maker_controller_publish_part.dart';
part 'url_post_maker_controller_ui_part.dart';
part 'url_post_maker_controller_base_part.dart';
part 'url_post_maker_controller_class_part.dart';
part 'url_post_maker_controller_facade_part.dart';
