import 'package:deliverance_desktop/models/base_search_object.dart';
import 'package:flutter/material.dart';

class CustomPaginator extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final List<int> pageSizeOptions;
  final BaseSearchObject searchObject;
  final Future<void> Function() onChanged;

  const CustomPaginator({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    required this.searchObject,
    required this.onChanged,
    this.pageSizeOptions = const [4, 8, 16, 32],
  });

  @override
  State<CustomPaginator> createState() => _CustomPaginatorState();
}

class _CustomPaginatorState extends State<CustomPaginator> {
  bool _isChanging = false;

  Future<void> _goToPage(int page) async {
    if (page < 1 ||
        page > widget.totalPages ||
        page == widget.currentPage ||
        _isChanging) {
      return;
    }
    setState(() => _isChanging = true);
    widget.searchObject.page = page;
    widget.searchObject.pageSize = widget.pageSize;
    await widget.onChanged();
    if (mounted) setState(() => _isChanging = false);
  }

  Future<void> _changePageSize(int size) async {
    if (size == widget.pageSize || _isChanging) return;
    setState(() => _isChanging = true);
    widget.searchObject.page = 1;
    widget.searchObject.pageSize = size;
    await widget.onChanged();
    if (mounted) setState(() => _isChanging = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canGoBack = widget.currentPage > 1 && !_isChanging;
    final canGoNext = widget.currentPage < widget.totalPages && !_isChanging;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RotatedBox(
          quarterTurns: 2,
          child: IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            color: canGoBack
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            onPressed: canGoBack
                ? () => _goToPage(widget.currentPage - 1)
                : null,
            iconSize: 40,
          ),
        ),
        const SizedBox(width: 20),
        Text(
          "${widget.totalPages == 0 ? 0 : widget.currentPage} of ${widget.totalPages}",
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(width: 20),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          color: canGoNext
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
          onPressed: canGoNext ? () => _goToPage(widget.currentPage + 1) : null,
          iconSize: 40,
        ),
        const SizedBox(width: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.primary),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: widget.pageSize,
              items: widget.pageSizeOptions
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.toString()),
                    ),
                  )
                  .toList(),
              onChanged: _isChanging
                  ? null
                  : (value) {
                      if (value != null) _changePageSize(value);
                    },
            ),
          ),
        ),
      ],
    );
  }
}
