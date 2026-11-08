import 'package:deliverance_desktop/utils/util_widgets.dart';
import 'package:deliverance_desktop/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

class SearchSortHeader extends StatefulWidget {
  final String searchHint;

  final double? searchFieldWidth;
  final String sortDialogTitle;
  final Map<String, String> sortColumns;
  final String? currentSortBy;
  final bool currentDescending;
  final void Function(String value) onSearch;
  final void Function(String sortBy, bool descending) onSort;

  const SearchSortHeader({
    super.key,
    required this.searchHint,
    this.searchFieldWidth = 400,
    required this.sortDialogTitle,
    required this.sortColumns,
    required this.currentSortBy,
    required this.currentDescending,
    required this.onSearch,
    required this.onSort,
  });

  @override
  State<SearchSortHeader> createState() => _SearchSortHeaderState();
}

class _SearchSortHeaderState extends State<SearchSortHeader> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;
  static const double _buttonsAreaHeight = 90;
  static const double _searchFieldHeight = 56;
  static const double _searchFieldGap = 20;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchField = Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: CustomTextField(
        controller: _searchController,
        hintText: widget.searchHint,
        width: widget.searchFieldWidth,
        onSubmited: widget.onSearch,
      ),
    );

    final buttonStyle = FilledButton.styleFrom(
      shape: CircleBorder(),
      backgroundColor: Theme.of(context).colorScheme.primary,
      padding: EdgeInsets.all(20),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
      height: _isSearchVisible
          ? _buttonsAreaHeight + _searchFieldGap + _searchFieldHeight
          : _buttonsAreaHeight,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.hardEdge,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 20,
            children: [
              FilledButton(
                onPressed: () {
                  setState(() {
                    _isSearchVisible = !_isSearchVisible;
                  });
                },
                style: buttonStyle,
                child: Icon(Icons.search, size: 50),
              ),
              FilledButton(
                onPressed: () {
                  showSortDialog(
                    context,
                    title: widget.sortDialogTitle,
                    columnNames: widget.sortColumns,
                    currentSortBy: widget.currentSortBy,
                    currentDescending: widget.currentDescending,
                    onApply: widget.onSort,
                  );
                },
                style: buttonStyle,
                child: Icon(Icons.sort, size: 50),
              ),
            ],
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOutCubic,
            top: _isSearchVisible
                ? _buttonsAreaHeight + _searchFieldGap
                : -_searchFieldHeight,
            left: 40,
            right: 40,
            child: AnimatedOpacity(
              duration: Duration(milliseconds: _isSearchVisible ? 600 : 200),
              opacity: _isSearchVisible ? 1.0 : 0.0,
              child: widget.searchFieldWidth == null
                  ? searchField
                  : UnconstrainedBox(child: searchField),
            ),
          ),
        ],
      ),
    );
  }
}
