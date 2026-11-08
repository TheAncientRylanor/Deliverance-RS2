import 'package:flutter/material.dart';

Widget globalLoadingSpinner({double size = 36, Color? color}) {
  return Center(
    child: SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 3.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? const Color.fromRGBO(255, 179, 0, 1.00),
        ),
      ),
    ),
  );
}
