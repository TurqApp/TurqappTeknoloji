import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_snapshot_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/ders_ve_sonuclar_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/soru_model.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'deneme_sinavi_yap_controller_class_part.dart';
part 'deneme_sinavi_yap_controller_base_part.dart';
part 'deneme_sinavi_yap_controller_fields_part.dart';
part 'deneme_sinavi_yap_controller_config_part.dart';
part 'deneme_sinavi_yap_controller_facade_part.dart';
part 'deneme_sinavi_yap_controller_lifecycle_part.dart';
part 'deneme_sinavi_yap_controller_runtime_part.dart';
part 'deneme_sinavi_yap_controller_shell_part.dart';
part 'deneme_sinavi_yap_controller_shell_content_part.dart';
