import 'package:deliverance_scout/utils/util_widgets.dart';
import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final double? width;
  final double height;
  final Icon? icon;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.width = 165,
    this.height = 50,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: SizedBox(
        width: width ?? double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: Size(double.infinity, height),
            backgroundColor: Theme.of(context).colorScheme.outline,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            side: BorderSide(color: Theme.of(context).colorScheme.surface),
          ),
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? globalLoadingSpinner(
                  size: height * 0.5,
                  color: Theme.of(context).colorScheme.surface,
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: icon != null
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 10,
                          children: [
                            Text(
                              label,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surface,
                                    fontSize: 22,
                                    fontWeight: FontWeight(400),
                                  ),
                            ),
                            icon!,
                          ],
                        )
                      : Text(
                          label,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.surface,
                                fontSize: 22,
                              ),
                        ),
                ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final double? width;
  final double height;
  final Icon? icon;
  final bool isLoading;
  const SecondaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.width = 165,
    this.height = 50,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: SizedBox(
        width: width ?? double.infinity,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: Size(double.infinity, height),
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? globalLoadingSpinner(
                  size: height * 0.5,
                  color: const Color.fromRGBO(255, 255, 255, 1.00),
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: icon != null
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 10,
                          children: [
                            Text(
                              label,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: const Color.fromRGBO(
                                      255,
                                      255,
                                      255,
                                      1.00,
                                    ),
                                    fontSize: 22,
                                  ),
                            ),
                            icon!,
                          ],
                        )
                      : Text(
                          label,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: const Color.fromRGBO(
                                  255,
                                  255,
                                  255,
                                  1.00,
                                ),
                                fontSize: 22,
                              ),
                        ),
                ),
        ),
      ),
    );
  }
}
