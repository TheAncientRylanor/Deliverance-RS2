import 'package:deliverance_mobile/providers/auth_provider.dart';
import 'package:deliverance_mobile/utils/api_client_exception.dart';
import 'package:deliverance_mobile/utils/form_validators.dart';
import 'package:deliverance_mobile/utils/server_field_errors.dart';
import 'package:deliverance_mobile/widgets/custom_buttons.dart';
import 'package:deliverance_mobile/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<bool?> resetPasswordDialog(BuildContext context) {
  final formKey = GlobalKey<FormState>();
  final serverErrors = ServerFieldErrors();
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController newRePasswordController = TextEditingController();
  final authProvider = context.read<AuthProvider>();
  bool hideCurrentPassword = true;
  bool hideNewPassword = true;
  bool isSaving = false;
  String? errorMessage;

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> onSave() async {
            serverErrors.clear();
            if (!formKey.currentState!.validate()) return;
            setDialogState(() {
              isSaving = true;
              errorMessage = null;
            });
            try {
              await authProvider.changePassword(
                currentPasswordController.text,
                newPasswordController.text,
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext, true);
            } on ApiClientException catch (e) {
              final shownOnField = serverErrors.show(e, formKey);
              setDialogState(() {
                isSaving = false;
                errorMessage = shownOnField ? null : e.message;
              });
            }
          }

          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            title: Center(child: Text("Change password")),
            titleTextStyle: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            content: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    CustomTextField(
                      labelText: "Current password",
                      obscureText: hideCurrentPassword,
                      controller: currentPasswordController,
                      validator: serverErrors.wrap(
                        'OldPassword',
                        requiredField('Current password'),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setDialogState(() {
                            hideCurrentPassword = !hideCurrentPassword;
                          });
                        },
                        icon: Icon(
                          hideCurrentPassword
                              ? Icons.visibility_off
                              : Icons.visibility_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    CustomTextField(
                      labelText: "New password",
                      obscureText: hideNewPassword,
                      controller: newPasswordController,
                      validator: serverErrors.wrap(
                        'NewPassword',
                        allOf([
                          password('New password'),
                          (value) => value == currentPasswordController.text
                              ? 'New password must be different from the current password'
                              : null,
                        ]),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setDialogState(() {
                            hideNewPassword = !hideNewPassword;
                          });
                        },
                        icon: Icon(
                          hideNewPassword
                              ? Icons.visibility_off
                              : Icons.visibility_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    CustomTextField(
                      labelText: "Repeat new password",
                      obscureText: hideNewPassword,
                      controller: newRePasswordController,
                      validator: allOf([
                        requiredField('Repeated new password'),
                        sameAs(
                          () => newPasswordController.text,
                          'Passwords do not match. Enter the same new password twice.',
                        ),
                      ]),
                    ),
                    if (errorMessage != null)
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    SizedBox(height: 20),
                    Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            onPressed: isSaving
                                ? null
                                : () {
                                    Navigator.pop(dialogContext, false);
                                  },
                            label: "Cancel",
                          ),
                        ),
                        Expanded(
                          child: PrimaryButton(
                            isLoading: isSaving,
                            onPressed: onSave,
                            label: "Save",
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
