part of 'search_deneme.dart';

extension SearchDenemeShellPart on _SearchDenemeState {
  Widget _buildSearchShell() {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
        child: Container(
          height: 50,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.black),
                Expanded(
                  child: TextField(
                    controller: controller.searchController,
                    focusNode: controller.focusNode,
                    onChanged: controller.filterSearchResults,
                    decoration: InputDecoration(
                      hintText: 'common.search'.tr,
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: "MontserratMedium",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
