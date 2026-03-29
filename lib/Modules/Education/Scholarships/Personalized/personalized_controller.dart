import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/scholarship_snapshot_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:turqappv2/Core/Utils/location_text_utils.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'personalized_controller_data_part.dart';
part 'personalized_controller_base_part.dart';
part 'personalized_controller_hooks_part.dart';
part 'personalized_controller_class_part.dart';
part 'personalized_controller_fields_part.dart';
part 'personalized_controller_score_part.dart';
part 'personalized_controller_runtime_part.dart';
part 'personalized_controller_support_part.dart';
