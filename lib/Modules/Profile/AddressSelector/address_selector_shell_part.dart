part of 'address_selector.dart';

extension AddressSelectorShellPart on _AddressSelectorState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Row(
                  children: [BackButtons(text: 'address.title'.tr)],
                ),
                const SizedBox(height: 12),
                _buildContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
