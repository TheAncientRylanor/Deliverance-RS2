import 'package:deliverance_scout/providers/scout_auth_provider.dart';
import 'package:deliverance_scout/utils/util_widgets.dart';
import 'package:deliverance_scout/widgets/custom_buttons.dart';
import 'package:deliverance_scout/widgets/scout_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Shown while ScoutAuthProvider polls the server: the token is claimed, but
/// the admin hasn't saved the device yet.
class AwaitingApprovalScreen extends StatelessWidget {
  const AwaitingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ScoutAuthProvider>();
    return ScoutPage(
      // Connection problems while polling.
      message: auth.message,
      isError: true,
      children: [
        globalLoadingSpinner(),
        Text(
          "Enrolled. Waiting for the admin to save this device "
          "in the Deliverance desktop app...",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        SecondaryButton(onPressed: () => auth.forget(), label: "Start over"),
      ],
    );
  }
}
