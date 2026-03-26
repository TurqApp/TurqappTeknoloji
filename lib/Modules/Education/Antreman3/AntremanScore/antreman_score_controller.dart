import 'dart:developer';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/antreman_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/rozet_permissions.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'antreman_score_controller_data_part.dart';
part 'antreman_score_controller_fields_part.dart';
part 'antreman_score_controller_rank_part.dart';
part 'antreman_score_controller_class_part.dart';
part 'antreman_score_controller_facade_part.dart';
