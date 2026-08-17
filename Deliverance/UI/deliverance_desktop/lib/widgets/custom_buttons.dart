import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final double? width;
  final double height;
  final Icon? icon;

  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.width = 165,
    this.height = 50,
    this.icon,
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
          onPressed: onPressed,
          child: icon != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.surface,
                              fontSize: 22,
                              fontWeight: FontWeight(400),
                            ),
                      ),
                    ),
                    icon!,
                  ],
                )
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.surface,
                    fontSize: 22,
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
  const SecondaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.width = 165,
    this.height = 50,
    this.icon,
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
          onPressed: onPressed,
          child: icon != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: const Color.fromRGBO(255, 255, 255, 1.00),
                              fontSize: 22,
                            ),
                      ),
                    ),
                    icon!,
                  ],
                )
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color.fromRGBO(255, 255, 255, 1.00),
                    fontSize: 22,
                  ),
                ),
        ),
      ),
    );
  }
}
