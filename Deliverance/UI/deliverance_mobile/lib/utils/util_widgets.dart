
import 'package:flutter/material.dart';
import 'package:deliverance_mobile/widgets/custom_buttons.dart';


Widget globalLoadingSpinner({double size = 36, Color? color}) {
  return Center(
    child: SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 3.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? const Color.fromRGBO(255, 179, 0, 1.00),
        ),
      ),
    ),
  );
}

enum AlertBoxMode { choice, ok }

Future<bool?> alertBox(
  BuildContext context,
  String title,
  String content, {
  AlertBoxMode mode = AlertBoxMode.choice,
}) {
  final theme = Theme.of(context);

  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actionsAlignment: MainAxisAlignment.center,
      title: Center(
        child: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      content: SelectableText(
        content,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
      actions: [
        if (mode == AlertBoxMode.choice)
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  label: "No",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  label: "Yes",
                ),
              ),
            ],
          )
        else
          PrimaryButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            label: "OK",
          ),
      ],
    ),
  );
}

void alertBoxMoveBack(
  BuildContext context,
  String title,
  String content, {
  VoidCallback? onRetry,
}) {
  final theme = Theme.of(context);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actionsAlignment: MainAxisAlignment.center,
      title: Center(
        child: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      content: SelectableText(
        content,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                label: "Back",
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onRetry();
                  },
                  label: "Retry",
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}


const String mField = "This filed is mandatory";

const String numericField = "This filed is numeric";

Future<void> showSortDialog(
  BuildContext context, {
  required String title,
  required Map<String, String> columnNames,
  required String? currentSortBy,
  required bool currentDescending,
  required void Function(String sortBy, bool descending) onApply,
}) {
  final theme = Theme.of(context);
  String? selectedColumn = currentSortBy;
  String sortOrder = currentDescending ? "Descending" : "Ascending";

  return showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, setState) {
          return Dialog(
            backgroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: 600,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Text(title, style: theme.textTheme.displayLarge),
                    const SizedBox(height: 20),
                    Text(
                      "Choose a column to sort by",
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      alignment: WrapAlignment.center,
                      children: [
                        for (var column in columnNames.entries)
                          SortColumnChip(
                            label: column.value,
                            selected: selectedColumn == column.key,
                            onTap: () {
                              setState(() {
                                selectedColumn = selectedColumn == column.key
                                    ? null
                                    : column.key;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SizeTransition(
                          sizeFactor: animation,
                          alignment: Alignment.topCenter,
                          child: child,
                        ),
                      ),
                      child: selectedColumn == null
                          ? const SizedBox.shrink(key: ValueKey('empty'))
                          : Text(
                              "Sorting by: ${columnNames[selectedColumn]}",
                              key: ValueKey(selectedColumn),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      spacing: 10,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SortOrderButton(
                          icon: Icons.arrow_upward,
                          selected: sortOrder == "Ascending",
                          onTap: () {
                            setState(() {
                              sortOrder = "Ascending";
                            });
                          },
                        ),
                        SortOrderButton(
                          icon: Icons.arrow_downward,
                          selected: sortOrder == "Descending",
                          onTap: () {
                            setState(() {
                              sortOrder = "Descending";
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      spacing: 10,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: "Cancel",
                            width: 150,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        Expanded(
                          child: PrimaryButton(
                            label: "Apply",
                            width: 150,
                            onPressed: selectedColumn == null
                                ? null
                                : () {
                                    Navigator.of(context).pop();
                                    onApply(
                                      selectedColumn!,
                                      sortOrder == "Descending",
                                    );
                                  },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class SortColumnChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SortColumnChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedScale(
      scale: selected ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? theme.colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : theme.colorScheme.outline,
                width: 1.5,
              ),
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              style: (theme.textTheme.headlineSmall ?? const TextStyle())
                  .copyWith(
                    fontSize: 18,
                    color: selected
                        ? theme.colorScheme.surface
                        : theme.colorScheme.onSurface,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}

class SortOrderButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const SortOrderButton({
    super.key,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedScale(
      scale: selected ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? theme.colorScheme.primary : Colors.transparent,
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                key: ValueKey(selected),
                size: 40,
                color: selected
                    ? theme.colorScheme.surface
                    : theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
