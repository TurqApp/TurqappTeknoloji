part of 'career_profile_controller.dart';

extension CareerProfileControllerActionsPart on CareerProfileController {
  Future<void> toggleFindingJob() async {
    try {
      isFindingJob.value = !isFindingJob.value;
      final uid = CurrentUserService.instance.effectiveUserId;
      if (uid.isEmpty) return;
      await FirebaseFirestore.instance
          .collection('CV')
          .doc(uid)
          .update({'findingJob': isFindingJob.value});
      final current = await _cvRepository.getCv(uid, preferCache: true);
      if (current != null) {
        current['findingJob'] = isFindingJob.value;
        await _cvRepository.setCv(uid, current);
      } else {
        await _cvRepository.invalidate(uid);
      }
    } catch (_) {
      isFindingJob.value = !isFindingJob.value;
    }
  }
}
