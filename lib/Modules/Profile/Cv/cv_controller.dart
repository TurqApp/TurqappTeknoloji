import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/cv_repository.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/Utils/phone_utils.dart';
import 'package:turqappv2/Core/Utils/url_utils.dart';
import 'package:turqappv2/Models/CVModels/school_model.dart';
import 'package:turqappv2/Modules/Profile/Cv/cv_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'cv_controller_sections_part.dart';
part 'cv_controller_class_part.dart';
part 'cv_controller_education_part.dart';
part 'cv_controller_experience_part.dart';
part 'cv_controller_facade_part.dart';
part 'cv_controller_fields_part.dart';
part 'cv_controller_persistence_part.dart';
part 'cv_controller_profile_part.dart';
