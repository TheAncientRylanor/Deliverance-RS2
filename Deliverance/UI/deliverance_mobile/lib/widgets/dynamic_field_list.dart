import 'package:deliverance_mobile/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

class DynamicFieldList extends StatelessWidget {
  final String labelText;
  final List<TextEditingController> controllers;
  final VoidCallback addFunction;
  final void Function(int index)? removeFunction;
  final void Function(int index)? onTap;
  final bool readOnly;
  final bool hasValidator;
  const DynamicFieldList({
    super.key,
    required this.labelText,
    required this.controllers,
    required this.addFunction,
    required this.hasValidator,
    this.removeFunction,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controllers.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(top: 15),
          child: LabeledInputWithAddButton(
            labelText: labelText,
            controller: controllers[index],
            index: index,
            length: controllers.length,
            addFunction: addFunction,
            removeFunction: removeFunction,
            onTap: onTap == null ? null : () => onTap!(index),
            readOnly: readOnly,
            hasValidator: hasValidator,
          ),
        );
      },
    );
  }
}

class LabeledInputWithAddButton extends StatelessWidget {
  final String? labelText;
  final TextEditingController controller;
  final int index;
  final int length;
  final VoidCallback addFunction;
  final VoidCallback? onTap;
  final void Function(int index)? removeFunction;
  final bool readOnly;
  final bool hasValidator;

  const LabeledInputWithAddButton({
    super.key,
    this.labelText,
    required this.controller,
    required this.index,
    required this.hasValidator,
    required this.length,
    required this.addFunction,
    this.removeFunction,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLastItem = index == length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CustomTextField(
          labelText: labelText,
          onTap: onTap,
          readOnly: readOnly,
          controller: controller,
          validator: hasValidator
              ? (value) {
                  if (value == null || value == "") {
                    return "$labelText cannot be an empty field";
                  }
                  return null;
                }
              : null,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 10,
          children: [
            if (index != 0)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: _RemoveFieldButton(
                  onPressed: removeFunction,
                  index: index,
                ),
              ),
            if (isLastItem)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: _AddFieldButton(onPressed: addFunction),
              ),
          ],
        ),
      ],
    );
  }
}

class _AddFieldButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddFieldButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 1.0,
        ),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
    );
  }
}

class _RemoveFieldButton extends StatelessWidget {
  final void Function(int index)? onPressed;
  final int index;
  const _RemoveFieldButton({required this.onPressed, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 1.0,
        ),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          onPressed != null ? onPressed!(index) : null;
        },
        icon: Icon(
          Icons.remove,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
    );
  }
}
