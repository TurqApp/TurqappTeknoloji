part of 'job_content_controller.dart';

class JobContentController extends GetxController {
  final JobRepository _jobRepository = ensureJobRepository();
  static final Map<String, Set<String>> _savedIdsByUser =
      <String, Set<String>>{};
  static final Map<String, Future<Set<String>>> _savedIdsLoaders =
      <String, Future<Set<String>>>{};
  var saved = false.obs;
  String _initializedSavedDocId = '';
}
