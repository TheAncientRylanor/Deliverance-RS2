import 'package:deliverance_scout/providers/scout_auth_provider.dart';
import 'package:deliverance_scout/widgets/custom_buttons.dart';
import 'package:deliverance_scout/widgets/scout_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScoutDisabledScreen extends StatefulWidget {
  const ScoutDisabledScreen({super.key});

  @override
  State<ScoutDisabledScreen> createState() => _ScoutDisabledScreenState();
}

class _ScoutDisabledScreenState extends State<ScoutDisabledScreen> {
  bool _isRefreshing = false;

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    await context.read<ScoutAuthProvider>().refresh();
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ScoutAuthProvider>();
    final textTheme = Theme.of(context).textTheme;
    return ScoutPage(
      message: auth.message,
      isError: true,
      children: [
        Text("Scout disabled", style: textTheme.labelLarge),
        Text(
          "This scout was disabled by an admin. It will start working again "
          "once an admin enables it in the Deliverance desktop app.",
          textAlign: TextAlign.center,
          style: textTheme.labelMedium,
        ),
        PrimaryButton(
          onPressed: _refresh,
          isLoading: _isRefreshing,
          label: "Refresh",
        ),
      ],
    );
  }
}
