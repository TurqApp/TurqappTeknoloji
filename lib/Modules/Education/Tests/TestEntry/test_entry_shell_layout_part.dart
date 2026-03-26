part of 'test_entry.dart';

extension _TestEntryShellLayoutPart on _TestEntryState {
  Widget _buildBodyLayout(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Column(
          children: [
            BackButtons(text: 'tests.join_title'.tr),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSearchField(),
                          const SizedBox(height: 15),
                          Text(
                            'tests.join_help'.tr,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                          const SizedBox(height: 20),
                          Obx(() => _buildSearchState()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Obx(() => _buildJoinButton(context)),
      ],
    );
  }
}
