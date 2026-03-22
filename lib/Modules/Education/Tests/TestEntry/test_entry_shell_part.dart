part of 'test_entry.dart';

extension _TestEntryShellPart on _TestEntryState {
  Widget _buildBody(BuildContext context) {
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

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: TextField(
          cursorColor: Colors.black,
          controller: controller.textController,
          focusNode: controller.focusNode,
          onChanged: controller.onTextChanged,
          onSubmitted: controller.onTextSubmitted,
          decoration: InputDecoration(
            icon: Icon(
              AppIcons.search,
              color: Colors.pink,
            ),
            hintText: 'tests.search_id_hint'.tr,
            hintStyle: const TextStyle(
              color: Colors.grey,
              fontFamily: 'Montserrat',
              fontSize: 15,
            ),
            border: InputBorder.none,
          ),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
    );
  }

  Widget _buildSearchState() {
    if (controller.isLoading.value) {
      return const Center(
        child: CupertinoActivityIndicator(
          radius: 20,
          color: Colors.black,
        ),
      );
    }
    if (controller.model.value == null &&
        controller.textController.text.length >= 10) {
      return Padding(
        padding: const EdgeInsets.all(15),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.black,
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                'tests.join_not_found'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (controller.model.value != null) {
      return _buildResultCard();
    }
    return const SizedBox.shrink();
  }

  Widget _buildJoinButton(BuildContext context) {
    if (controller.model.value == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => controller.joinTest(context),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: SizedBox(
          height: 50,
          child: Material(
            color: Colors.black,
            borderRadius: BorderRadius.all(Radius.circular(12)),
            child: Center(
              child: _JoinButtonText(),
            ),
          ),
        ),
      ),
    );
  }
}

class _JoinButtonText extends StatelessWidget {
  const _JoinButtonText();

  @override
  Widget build(BuildContext context) {
    return Text(
      'tests.join_button'.tr,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontFamily: 'MontserratMedium',
      ),
    );
  }
}
