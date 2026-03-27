import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/cv_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Models/CVModels/school_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'career_profile_controller_facade_part.dart';
part 'career_profile_controller_fields_part.dart';
part 'career_profile_controller_runtime_part.dart';
