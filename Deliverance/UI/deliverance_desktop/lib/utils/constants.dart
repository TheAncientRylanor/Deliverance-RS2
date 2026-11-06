import 'package:deliverance_desktop/models/office.dart';
import 'package:flutter/material.dart';

String iconForType(String type) {
  switch (type) {
    case "Computer":
      return 'assets/icons/computer.svg';
    case "Laptop":
      return 'assets/icons/laptop.svg';
    case "Server":
      return 'assets/icons/server.svg';
    case "Projector":
      return 'assets/icons/projector.svg';
    case "Switch":
      return 'assets/icons/switch.svg';
    case "Router":
      return 'assets/icons/router.svg';
    default:
      return 'assets/icons/computer.svg';
  }
}

/// White for regular devices, the primary color for scouts, and a faded
/// primary color for disabled scouts.
ColorFilter deviceColorFilter(Scout? scout, BuildContext context) {
  final primary = Theme.of(context).colorScheme.primary;
  if (scout == null) {
    return const ColorFilter.mode(Colors.white, BlendMode.srcIn);
  }
  return ColorFilter.mode(
    scout.isDisabled ? primary.withAlpha(120) : primary,
    BlendMode.srcIn,
  );
}
