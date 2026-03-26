import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/tutoring_snapshot_repository.dart';
import 'package:turqappv2/Core/Utils/location_text_utils.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'location_based_tutoring_controller_class_part.dart';
part 'location_based_tutoring_controller_facade_part.dart';
part 'location_based_tutoring_controller_fields_part.dart';
part 'location_based_tutoring_controller_runtime_part.dart';
part 'location_based_tutoring_controller_support_part.dart';
