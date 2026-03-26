part of 'answer_key.dart';

extension AnswerKeyShellPart on AnswerKey {
  Widget _buildPage(BuildContext context) {
    final bodyContent = _buildBodyContent();
    final overlays = _buildOverlays(context);

    if (embedded) {
      return _buildEmbeddedPage(
        bodyContent: bodyContent,
        overlays: overlays,
      );
    }

    return _buildStandalonePage(
      context,
      bodyContent: bodyContent,
      overlays: overlays,
    );
  }
}
