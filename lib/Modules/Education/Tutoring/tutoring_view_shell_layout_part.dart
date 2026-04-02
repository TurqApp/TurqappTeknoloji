part of 'tutoring_view.dart';

extension TutoringViewShellLayoutPart on TutoringView {
  Widget _buildPageLayout(BuildContext context) {
    ensureSavedTutoringsController(permanent: true);
    final bodyContent = _buildBodyContent(context);
    final overlays = _buildOverlays(context);

    if (embedded) {
      if (!showEmbeddedControls) {
        return Column(
          children: [
            bodyContent,
          ],
        );
      }

      return Stack(
        children: [
          Column(
            children: [
              bodyContent,
              15.ph,
            ],
          ),
          if (showEmbeddedControls) ...overlays,
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                bodyContent,
                15.ph,
              ],
            ),
            ...overlays,
          ],
        ),
      ),
    );
  }
}
