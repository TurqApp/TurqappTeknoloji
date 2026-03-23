part of 'deneme_turleri_listesi.dart';

extension DenemeTurleriListesiShellPart on _DenemeTurleriListesiState {
  Widget _buildDenemeTurleriListesiBody() {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          BackButtons(text: widget.sinavTuru),
          Expanded(child: _buildDenemeTurleriListesiContent()),
        ],
      ),
    );
  }
}
