import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final bool obscureText;
  final String? hintText;
  final String? labelText;
  final TextInputType? keyboardType;
  final VoidCallback? onTap;
  final bool? readOnly;
  final FormFieldValidator? validator;
  final TextStyle? textStyle;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  const CustomTextField({
    super.key,
    this.controller,
    this.obscureText = false,
    this.hintText,
    this.labelText,
    this.keyboardType,
    this.onTap,
    this.readOnly,
    this.validator,
    this.textStyle,
    this.minLines,
    this.maxLines,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onTap: onTap,
      validator: validator,
      minLines: minLines,
      maxLines: maxLines ?? 1,
      maxLength: maxLength,
      readOnly: readOnly == null ? false : readOnly as bool,
      style: Theme.of(context).textTheme.labelSmall,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: Colors.white70),
        filled: true,
        errorStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 14.0,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        ),
        fillColor: Theme.of(context).colorScheme.surfaceContainer,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 2.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 2.0,
          ),
        ),
      ),
    );

    if (labelText == null || labelText!.isEmpty) {
      return field;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            labelText!,
            style:
                textStyle ??
                Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color.fromRGBO(255, 255, 255, 1.00),
                ),
          ),
        ),
        field,
      ],
    );
  }
}
