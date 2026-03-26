part of 'booklet_answer.dart';

extension _BookletAnswerShellPart on _BookletAnswerState {
  Widget _buildBody(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildQuestionList()),
          ],
        ),
        _buildResultDialog(context),
      ],
    );
  }
}
