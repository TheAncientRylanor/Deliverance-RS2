import 'package:flutter/material.dart';

class ScoutPage extends StatelessWidget {
  final List<Widget> children;
  final String? message;
  final bool isError;

  const ScoutPage({
    super.key,
    required this.children,
    this.message,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 30,
              children: [
                Text(
                  "Scout device of Deliverance",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayLarge,
                ),
                ...children,
                if (message != null)
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isError ? theme.colorScheme.primary : Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
