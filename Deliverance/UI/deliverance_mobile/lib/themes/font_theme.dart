import 'package:flutter/material.dart';

TextTheme createFontScheme() {
  return const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Abel',
      fontSize: 40,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.25,
      color: Color.fromRGBO(255, 255, 255, 1.00),

      shadows: [
        Shadow(
          blurRadius: 10.0,
          color: Colors.black54,
          offset: Offset(4.0, 4.0),
        ),
      ],
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Abel',
      fontSize: 32,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Abel',
      fontSize: 28,
      fontWeight: FontWeight.w200,
      shadows: [
        Shadow(
          blurRadius: 10.0,
          color: Colors.black54,
          offset: Offset(4.0, 4.0),
        ),
      ],
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Abel',
      fontSize: 16,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.5,
      shadows: [
        Shadow(
          blurRadius: 10.0,
          color: Colors.black54,
          offset: Offset(4.0, 4.0),
        ),
      ],
    ),
    labelSmall: TextStyle(
      fontFamily: 'Abel',
      fontSize: 14,
      fontWeight: FontWeight.w700,
      shadows: [
        Shadow(
          blurRadius: 10.0,
          color: Colors.black54,
          offset: Offset(4.0, 4.0),
        ),
      ],
    ),
    labelMedium: TextStyle(
      fontFamily: 'Abel',
      fontSize: 22,
      fontWeight: FontWeight.w300,
      shadows: [
        Shadow(
          blurRadius: 10.0,
          color: Colors.black54,
          offset: Offset(4.0, 4.0),
        ),
      ],
    ),
    labelLarge: TextStyle(
      fontFamily: 'Abel',
      fontSize: 22,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          blurRadius: 10.0,
          color: Colors.black54,
          offset: Offset(4.0, 4.0),
        ),
      ],
    ),
    titleSmall: TextStyle(
      fontFamily: 'Abel',
      fontSize: 24,
      fontWeight: FontWeight.w800,
      shadows: [
        Shadow(
          blurRadius: 10.0,
          color: Colors.black54,
          offset: Offset(4.0, 4.0),
        ),
      ],
    ),
  );
}
