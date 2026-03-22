import 'package:get/get.dart';
import '../Models/report_model.dart';

List<ReportModel> get reportSelections => [
      ReportModel(
        key: "impersonation",
        title: 'report.reason.impersonation.title'.tr,
        description: 'report.reason.impersonation.desc'.tr,
      ),
      ReportModel(
        key: "copyright",
        title: 'report.reason.copyright.title'.tr,
        description: 'report.reason.copyright.desc'.tr,
      ),
      ReportModel(
        key: "harassment",
        title: 'report.reason.harassment.title'.tr,
        description: 'report.reason.harassment.desc'.tr,
      ),
      ReportModel(
        key: "hate_speech",
        title: 'report.reason.hate_speech.title'.tr,
        description: 'report.reason.hate_speech.desc'.tr,
      ),
      ReportModel(
        key: "nudity",
        title: 'report.reason.nudity.title'.tr,
        description: 'report.reason.nudity.desc'.tr,
      ),
      ReportModel(
        key: "violence",
        title: 'report.reason.violence.title'.tr,
        description: 'report.reason.violence.desc'.tr,
      ),
      ReportModel(
        key: "spam",
        title: 'report.reason.spam.title'.tr,
        description: 'report.reason.spam.desc'.tr,
      ),
      ReportModel(
        key: "scam",
        title: 'report.reason.scam.title'.tr,
        description: 'report.reason.scam.desc'.tr,
      ),
      ReportModel(
        key: "misinformation",
        title: 'report.reason.misinformation.title'.tr,
        description: 'report.reason.misinformation.desc'.tr,
      ),
      ReportModel(
        key: "illegal_content",
        title: 'report.reason.illegal_content.title'.tr,
        description: 'report.reason.illegal_content.desc'.tr,
      ),
      ReportModel(
        key: "child_safety",
        title: 'report.reason.child_safety.title'.tr,
        description: 'report.reason.child_safety.desc'.tr,
      ),
      ReportModel(
        key: "self_harm",
        title: 'report.reason.self_harm.title'.tr,
        description: 'report.reason.self_harm.desc'.tr,
      ),
      ReportModel(
        key: "privacy_violation",
        title: 'report.reason.privacy_violation.title'.tr,
        description: 'report.reason.privacy_violation.desc'.tr,
      ),
      ReportModel(
        key: "fake_engagement",
        title: 'report.reason.fake_engagement.title'.tr,
        description: 'report.reason.fake_engagement.desc'.tr,
      ),
      ReportModel(
        key: "other",
        title: 'report.reason.other.title'.tr,
        description: 'report.reason.other.desc'.tr,
      ),
    ];
