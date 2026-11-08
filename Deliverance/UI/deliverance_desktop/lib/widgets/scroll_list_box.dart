import 'package:deliverance_desktop/utils/util_widgets.dart';
import 'package:flutter/material.dart';

class ScrollListBox extends StatefulWidget {
  final bool isLoading;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final String emptyMessage;
  final double height;

  const ScrollListBox({
    super.key,
    required this.isLoading,
    required this.itemCount,
    required this.itemBuilder,
    required this.emptyMessage,
    this.height = 280,
  });

  @override
  State<ScrollListBox> createState() => _ScrollListBoxState();
}

class _ScrollListBoxState extends State<ScrollListBox> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border.all(color: theme.colorScheme.primary),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: widget.isLoading
          ? globalLoadingSpinner()
          : widget.itemCount == 0
          ? Center(
              child: Text(
                widget.emptyMessage,
                style: theme.textTheme.labelMedium,
              ),
            )
          : Scrollbar(
              controller: _controller,
              thumbVisibility: true,
              child: ListView.separated(
                controller: _controller,
                padding: const EdgeInsets.all(12),
                itemCount: widget.itemCount,
                itemBuilder: widget.itemBuilder,
                separatorBuilder: (context, index) =>
                    Divider(color: theme.colorScheme.primary, height: 16),
              ),
            ),
    );
  }
}
