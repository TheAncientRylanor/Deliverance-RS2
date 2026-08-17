import 'package:flutter/material.dart';

enum DropDownMode { single, multi }

class CustomDropDown<T> extends StatefulWidget {
  final String label;
  final Map<T, String> items;
  final DropDownMode mode;

  final T? initialValue;

  final List<T>? initialValues;

  final ValueChanged<T?>? onChanged;
  final ValueChanged<List<String>>? onChangedMulti;

  final TextStyle? textStyle;

  const CustomDropDown({
    super.key,
    required this.label,
    required this.items,
    this.mode = DropDownMode.single,
    this.initialValue,
    this.initialValues,
    this.onChanged,
    this.onChangedMulti,
    this.textStyle,
  });
  @override
  State<CustomDropDown<T>> createState() => _CustomDropDownState<T>();
}

class _CustomDropDownState<T> extends State<CustomDropDown<T>> {
  T? selectedValue;
  late List<T> selectedValues;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
    selectedValues = List<T>.from(widget.initialValues ?? const []);
  }

  InputDecorationTheme _inputDecorationTheme(BuildContext context) {
    return InputDecorationTheme(
      fillColor: Colors.transparent,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  Future<void> _openMultiSelect(BuildContext context) async {
    final result = await showDialog<List<T>>(
      context: context,
      builder: (dialogContext) {
        final tempSelected = List<T>.from(selectedValues);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(widget.label),
              content: SizedBox(
                width: 300,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.items.entries.map((entry) {
                      final isChecked = tempSelected.contains(entry.key);
                      return CheckboxListTile(
                        value: isChecked,
                        title: Text(entry.value),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (checked) {
                          setDialogState(() {
                            if (checked == true) {
                              tempSelected.add(entry.key);
                            } else {
                              tempSelected.remove(entry.key);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(tempSelected),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedValues = result;
      });
      widget.onChangedMulti?.call(
        selectedValues.map((v) => widget.items[v] ?? '').toList(),
      );
    }
  }

  String get _multiSelectDisplayText {
    if (selectedValues.isEmpty) return '';
    return selectedValues
        .map((v) => widget.items[v])
        .whereType<String>()
        .join(', ');
  }

  Widget _buildSingleDropDown(BuildContext context) {
    return DropdownMenu<T>(
      enableSearch: false,
      selectOnly: true,
      width: 300,
      initialSelection: selectedValue,
      trailingIcon: Icon(
        Icons.arrow_drop_down,
        color: Theme.of(context).colorScheme.primary,
      ),
      onSelected: (T? value) {
        setState(() {
          selectedValue = value;
        });
        widget.onChanged?.call(value);
      },
      textStyle: Theme.of(context).textTheme.labelMedium,
      dropdownMenuEntries: widget.items.entries.map<DropdownMenuEntry<T>>((
        MapEntry<T, String> entry,
      ) {
        return DropdownMenuEntry<T>(value: entry.key, label: entry.value);
      }).toList(),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.transparent),
      ),
      inputDecorationTheme: _inputDecorationTheme(context),
    );
  }

  Widget _buildMultiDropDown(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _openMultiSelect(context),
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.transparent,
          border: _inputDecorationTheme(context).enabledBorder,
          enabledBorder: _inputDecorationTheme(context).enabledBorder,
          focusedBorder: _inputDecorationTheme(context).focusedBorder,
          suffixIcon: Icon(
            Icons.arrow_drop_down,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        child: Text(
          _multiSelectDisplayText,
          style: widget.textStyle ?? Theme.of(context).textTheme.labelMedium,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Text(
            widget.label,
            style: widget.textStyle ?? Theme.of(context).textTheme.labelMedium,
          ),
          widget.mode == DropDownMode.single
              ? _buildSingleDropDown(context)
              : _buildMultiDropDown(context),
        ],
      ),
    );
  }
}
