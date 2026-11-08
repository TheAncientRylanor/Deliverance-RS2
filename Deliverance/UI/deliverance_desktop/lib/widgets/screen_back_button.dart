import 'package:deliverance_desktop/widgets/custom_buttons.dart';
import 'package:flutter/material.dart';

class ScreenBackButton extends StatelessWidget {
  final Future<bool> Function()? confirmLeave;

  const ScreenBackButton({super.key, this.confirmLeave});

  Future<void> _goBack(BuildContext context) async {
    final confirm = confirmLeave;
    if (confirm != null && !await confirm()) return;
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (!Navigator.of(context).canPop()) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: SecondaryButton(
        onPressed: () => _goBack(context),
        label: "Back",
        width: 120,
      ),
    );
  }
}
