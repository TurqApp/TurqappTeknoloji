part of 'job_repository.dart';

JobRepository? maybeFindJobRepository() =>
    Get.isRegistered<JobRepository>() ? Get.find<JobRepository>() : null;

JobRepository ensureJobRepository() =>
    maybeFindJobRepository() ?? Get.put(JobRepository(), permanent: true);
