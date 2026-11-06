import 'package:deliverance_desktop/widgets/custom_buttons.dart';
import 'package:deliverance_desktop/widgets/custom_text_field.dart';
import 'package:deliverance_desktop/widgets/office_editor/office_validators.dart';
import 'package:flutter/material.dart';

/// Asks for the office's name before saving. Returns the trimmed name, or
/// null when cancelled.
Future<String?> showOfficeNameDialog(BuildContext context, String initialName) {
  return showDialog<String>(
    context: context,
    builder: (_) => _OfficeNameDialog(initialName: initialName),
  );
}

class _OfficeNameDialog extends StatefulWidget {
  final String initialName;

  const _OfficeNameDialog({required this.initialName});

  @override
  State<_OfficeNameDialog> createState() => _OfficeNameDialogState();
}

class _OfficeNameDialogState extends State<_OfficeNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _nameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      insetPadding: const EdgeInsets.all(10),
      child: SizedBox(
        width: 400,
        height: 400,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10,
            children: [
              Text(
                "Please insert office name",
                style: theme.textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              Form(
                key: _formKey,
                child: CustomTextField(
                  controller: _nameController,
                  validator: (value) => validateOfficeName(value as String?),
                  onSubmited: (_) => _submit(),
                ),
              ),
              Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: PrimaryButton(onPressed: _submit, label: "Save"),
                  ),
                  Expanded(
                    child: SecondaryButton(
                      onPressed: () => Navigator.pop(context),
                      label: "Cancel",
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
