part of 'saved_optical_forms_controller.dart';

extension SavedOpticalFormsControllerFacadePart on SavedOpticalFormsController {
  bool _sameBookletEntries(
    List<BookletModel> current,
    List<BookletModel> next,
  ) =>
      SavedOpticalFormsControllerRuntimePart(this).sameBookletEntries(
        current,
        next,
      );

  Future<void> _bootstrapData() =>
      SavedOpticalFormsControllerRuntimePart(this).bootstrapData();

  Future<void> getData({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      SavedOpticalFormsControllerRuntimePart(this).getData(
        silent: silent,
        forceRefresh: forceRefresh,
      );
}
