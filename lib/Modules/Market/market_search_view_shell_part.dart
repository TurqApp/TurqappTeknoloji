part of 'market_search_view.dart';

extension _MarketSearchViewShellPart on _MarketSearchViewState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(context),
            const SizedBox(height: 10),
            Expanded(child: _buildSearchResultsBody()),
          ],
        ),
      ),
    );
  }
}
