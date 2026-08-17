import 'package:flutter/material.dart';

class CustomDropDown<T> extends StatefulWidget {
  final String label;
  final Map<T, String> items;
  final T? initialValue;
  final ValueChanged<T?>? onChanged;
  const CustomDropDown({
    super.key,
    required this.label,
    required this.items,
    this.initialValue,
    this.onChanged,
  });
  @override
  State<CustomDropDown<T>> createState() => _CustomDropDownState<T>();
}

class _CustomDropDownState<T> extends State<CustomDropDown<T>> {
  T? selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
  }

  void selectedKey() {}
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Text(widget.label, style: Theme.of(context).textTheme.labelMedium),
          DropdownMenu<T>(
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
            dropdownMenuEntries: widget.items.entries.map<DropdownMenuEntry<T>>(
              (MapEntry<T, String> entry) {
                return DropdownMenuEntry<T>(
                  value: entry.key,
                  label: entry.value,
                );
              },
            ).toList(),
            menuStyle: MenuStyle(
              backgroundColor: WidgetStateProperty.all(Colors.transparent),
            ),
            inputDecorationTheme: InputDecorationTheme(
              fillColor: Colors.transparent,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
