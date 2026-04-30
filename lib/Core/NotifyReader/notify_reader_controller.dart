import 'dart:async';

import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/education_detail_navigation_service.dart';
import 'package:turqappv2/Core/Services/market_detail_navigation_service.dart';
import 'package:turqappv2/Core/Services/profile_navigation_service.dart';
import 'package:turqappv2/Runtime/app_root_navigation_service.dart';
import 'package:turqappv2/Core/Repositories/notify_lookup_repository.dart';
import 'package:turqappv2/Core/NotifyReader/notify_reader_route_decision.dart';

import '../../Modules/Agenda/FloodListing/flood_listing.dart';
import '../../Modules/Agenda/SinglePost/single_post.dart';
import '../../Modules/Chat/chat.dart';
import '../../Models/notification_model.dart';

part 'notify_reader_controller_base_part.dart';
part 'notify_reader_controller_facade_part.dart';
part 'notify_reader_controller_fields_part.dart';
part 'notify_reader_controller_navigation_part.dart';
part 'notify_reader_controller_runtime_part.dart';
