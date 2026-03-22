part of 'search_tests.dart';

extension _SearchTestsShellPart on _SearchTestsState {
  Widget _buildPage() {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'tests.search_title'.tr),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildSearchField(),
                    _buildGridContent(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: 15,
          right: 15,
          left: 15,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.all(
              Radius.circular(12),
            ),
          ),
          child: TextField(
            cursorColor: Colors.black,
            controller: controller.searchController,
            focusNode: controller.focusNode,
            onChanged: controller.filterSearchResults,
            decoration: InputDecoration(
              hintText: 'common.search'.tr,
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: Icon(
                AppIcons.search,
                color: Colors.pink,
              ),
              border: const OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: 'MontserratMedium',
            ),
          ),
        ),
      ),
    );
  }
}
