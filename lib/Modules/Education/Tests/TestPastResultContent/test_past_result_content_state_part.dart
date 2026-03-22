part of 'test_past_result_content.dart';

extension _TestPastResultContentStatePart on _TestPastResultContentState {
  Widget _buildBody() {
    if (controller.isLoading.value) {
      return const Padding(
        padding: EdgeInsets.all(15),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    if (controller.count.value == 0) {
      return Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, color: Colors.black, size: 40),
            const SizedBox(height: 10),
            Text(
              'tests.result_answer_missing'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
      );
    }

    return Column(children: [_buildResultCard()]);
  }
}
