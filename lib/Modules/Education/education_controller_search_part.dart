part of 'education_controller.dart';

extension EducationControllerSearchPart on EducationController {
  void _performResetVisibleSearchOnReturn() {
    final activeTab = selectedTab.value;
    searchFocus.unfocus();
    tabSearchQueries[activeTab] = '';
    if (searchController.text.isNotEmpty) {
      searchController.clear();
    }
    searchText.value = '';
    isKeyboardOpen.value = false;
    isSearchMode.value = false;
    _clearModuleSearch(activeTab);
  }

  void clearSearch(BuildContext context) {
    searchFocus.unfocus();
    tabSearchQueries[selectedTab.value] = '';
    searchController.clear();
    searchText.value = '';
    isKeyboardOpen.value = false;
    isSearchMode.value = false;
    _clearModuleSearch(selectedTab.value);
    FocusScope.of(context).unfocus();
  }

  void updateSearchText(String value) {
    tabSearchQueries[selectedTab.value] = value;
    searchText.value = value;
  }

  void _restoreSearchForTab(int tabIndex) {
    final query = tabSearchQueries[tabIndex] ?? '';
    searchController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    if (query.isEmpty && searchFocus.hasFocus) {
      searchFocus.unfocus();
      isKeyboardOpen.value = false;
      isSearchMode.value = false;
    }
    if (searchText.value != query) {
      searchText.value = query;
    } else {
      _forwardSearch();
    }
  }

  void _forwardSearch() {
    final query = searchText.value;
    switch (titles[selectedTab.value]) {
      case PasajTabIds.scholarships:
        ScholarshipsController.maybeFind()?.setSearchQuery(query);
        break;
      case PasajTabIds.jobFinder:
        final jc = JobFinderController.maybeFind();
        if (jc != null) {
          jc.search.text = query;
        }
        break;
      case PasajTabIds.market:
        MarketController.maybeFind()?.setSearchQuery(query);
        break;
      case PasajTabIds.questionBank:
        AntremanController.maybeFind()?.setSearchQuery(query);
        break;
      case PasajTabIds.practiceExams:
        CikmisSorularController.maybeFind()?.setSearchQuery(query);
        break;
      case PasajTabIds.onlineExam:
        DenemeSinavlariController.maybeFind()?.setSearchQuery(query);
        break;
      case PasajTabIds.answerKey:
        AnswerKeyController.maybeFind()?.setSearchQuery(query);
        break;
      case PasajTabIds.tutoring:
        TutoringController.maybeFind()?.setSearchQuery(query);
        break;
    }
  }

  void _clearModuleSearch(int tabIndex) {
    switch (titles[tabIndex]) {
      case PasajTabIds.scholarships:
        ScholarshipsController.maybeFind()?.setSearchQuery('');
        break;
      case PasajTabIds.jobFinder:
        JobFinderController.maybeFind()?.search.clear();
        break;
      case PasajTabIds.market:
        MarketController.maybeFind()?.setSearchQuery('');
        break;
      case PasajTabIds.questionBank:
        AntremanController.maybeFind()?.setSearchQuery('');
        break;
      case PasajTabIds.practiceExams:
        CikmisSorularController.maybeFind()?.setSearchQuery('');
        break;
      case PasajTabIds.onlineExam:
        DenemeSinavlariController.maybeFind()?.setSearchQuery('');
        break;
      case PasajTabIds.answerKey:
        AnswerKeyController.maybeFind()?.setSearchQuery('');
        break;
      case PasajTabIds.tutoring:
        TutoringController.maybeFind()?.setSearchQuery('');
        break;
    }
  }
}
