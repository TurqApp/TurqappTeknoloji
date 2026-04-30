import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nsfw_detector_flutter/nsfw_detector_flutter.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/external.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/text_moderation_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/SinavSorusuHazirla/sinav_sorusu_hazirla.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'sinav_hazirla_controller_class_part.dart';
part 'sinav_hazirla_controller_base_part.dart';
part 'sinav_hazirla_controller_fields_part.dart';
part 'sinav_hazirla_controller_facade_part.dart';
part 'sinav_hazirla_controller_form_part.dart';
part 'sinav_hazirla_controller_submission_part.dart';

const _sinavTuruLgs = 'LGS';
const _sinavTuruTyt = 'TYT';
const _sinavTuruAyt = 'AYT';
const _sinavTuruKpss = 'KPSS';
const _sinavTuruAles = 'ALES';
const _sinavTuruDgs = 'DGS';

const _kpssLisansOrtaogretim = 'Ortaöğretim';
const _kpssLisansLegacyOrtaOgretim = 'Orta Öğretim';
const _kpssLisansOnLisans = 'Ön Lisans';
const _kpssLisansLisans = 'Lisans';
const _kpssLisansEgitimBirimleri = 'Eğitim Birimleri';
const _kpssLisansAGrubu1 = 'A Grubu 1';
const _kpssLisansAGrubu2 = 'A Grubu 2';
