import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageByteFormat;
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Utils/nickname_utils.dart';
import 'package:turqappv2/Core/Utils/url_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import '../../../Core/Helpers/QRCode/qr_scanner_view.dart';

part 'my_q_r_code_controller_class_part.dart';
part 'my_q_r_code_controller_base_part.dart';
part 'my_q_r_code_controller_runtime_part.dart';
