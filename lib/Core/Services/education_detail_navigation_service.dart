import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Modules/Education/Tutoring/CreateTutoring/create_tutoring_view.dart';
import 'package:turqappv2/Modules/Education/Tutoring/LocationBasedTutoring/location_based_tutoring.dart';
import 'package:turqappv2/Modules/Education/Tutoring/MyTutoringApplications/my_tutoring_applications.dart';
import 'package:turqappv2/Modules/Education/Tutoring/MyTutorings/my_tutorings.dart';
import 'package:turqappv2/Modules/Education/Tutoring/SavedTutorings/saved_tutorings.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringDetail/tutoring_detail.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringSearch/tutoring_search.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_content.dart';
import 'package:turqappv2/Modules/JobFinder/CareerProfile/career_profile.dart';
import 'package:turqappv2/Modules/JobFinder/JobCreator/job_creator.dart';
import 'package:turqappv2/Modules/JobFinder/JobDetails/job_details.dart';
import 'package:turqappv2/Modules/JobFinder/MyApplications/my_applications.dart';
import 'package:turqappv2/Modules/JobFinder/MyJobAds/my_job_ads.dart';
import 'package:turqappv2/Modules/JobFinder/SavedJobs/saved_jobs.dart';
import 'package:turqappv2/Modules/Profile/Cv/cv.dart';

class EducationDetailNavigationService {
  const EducationDetailNavigationService();

  Future<void> openCareerProfile() async {
    await Get.to(() => CareerProfile());
  }

  Future<void> openCv() async {
    await Get.to(() => Cv());
  }

  Future<void> openCreateTutoring({TutoringModel? existingTutoring}) async {
    await Get.to(CreateTutoringView(), arguments: existingTutoring);
  }

  Future<JobModel?> openJobCreator({JobModel? existingJob}) async {
    return Get.to<JobModel?>(() => JobCreator(existingJob: existingJob));
  }

  Future<void> openJobDetails(JobModel model) async {
    await Get.to(() => JobDetails(model: model));
  }

  Future<void> openLocationBasedTutoring() async {
    await Get.to(() => LocationBasedTutoring());
  }

  Future<void> openMyJobAds() async {
    await Get.to(() => MyJobAds());
  }

  Future<void> openMyJobApplications() async {
    await Get.to(() => MyApplications());
  }

  Future<void> openMyTutoringApplications() async {
    await Get.to(() => MyTutoringApplications());
  }

  Future<void> openMyTutorings() async {
    await Get.to(MyTutorings());
  }

  Future<void> openSavedJobs() async {
    await Get.to(() => SavedJobs());
  }

  Future<void> openSavedTutorings() async {
    await Get.to(() => SavedTutorings());
  }

  Future<void> openTutoringCategory(String categoryName) async {
    await Get.to(() => TutoringContent(categoryName: categoryName));
  }

  Future<void> openTutoringDetail(TutoringModel model) async {
    await Get.to(() => TutoringDetail(), arguments: model);
  }

  Future<void> openTutoringSearch() async {
    await Get.to(() => const TutoringSearch());
  }

  Future<void> replaceWithJobDetails(JobModel model) async {
    await Get.off(() => JobDetails(model: model));
  }

  Future<void> replaceWithTutoringDetail(TutoringModel model) async {
    await Get.off(() => TutoringDetail(), arguments: model);
  }
}
