import 'package:deliverance_desktop/providers/auth_provider.dart';
import 'package:deliverance_desktop/utils/api_client_exception.dart';
import 'package:deliverance_desktop/widgets/custom_buttons.dart';
import 'package:deliverance_desktop/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Returns true when the password was changed. The user is logged out at that
/// point, since the backend revokes all of their refresh tokens.
Future<bool?> resetPasswordDialog(BuildContext context) {
  final formKey = GlobalKey<FormState>();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final newRePasswordController = TextEditingController();
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
              setDialogState(() {
                isSaving = false;
                errorMessage = e.message;
              });
            }
          }

          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            title: const Center(child: Text("Reset password")),
            titleTextStyle: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            content: SizedBox(
              width: 440,
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 16,
                    children: [
                      CustomTextField(
                        labelText: "Current password",
                        obscureText: hideCurrentPassword,
                        controller: currentPasswordController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your current password';
                          }
                          return null;
                        },
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a new password';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters long';
                          }
                          if (value == currentPasswordController.text) {
                            return "Password can't be the same as the previous password";
                          }
                          return null;
                        },
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
                        validator: (value) {
                          if (value != newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      if (errorMessage != null)
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        spacing: 12,
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
            ),
          );
        },
      );
    },
  );
}
