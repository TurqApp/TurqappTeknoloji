part of 'my_statistic_view.dart';

extension _MyStatisticViewShellPart on _MyStatisticViewState {
  Widget _buildMyStatisticShell(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          return RefreshIndicator(
            backgroundColor: Colors.black,
            color: Colors.white,
            onRefresh: controller.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  BackButtons(text: 'statistics.title'.tr),
                  if (controller.isLoading.value)
                    const Padding(
                      padding: EdgeInsets.all(15),
                      child: Center(child: CupertinoActivityIndicator()),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: _buildMyStatisticContent(),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
