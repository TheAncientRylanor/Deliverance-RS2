// ignore_for_file: file_names

import 'package:flutter/material.dart';

TextTheme createFontScheme() {
  return const TextTheme(
    // Used for massive header styles
    displayLarge: TextStyle(
      fontFamily: 'Abel',
      fontSize: 40,
      letterSpacing: -0.25,
      color: Color.fromRGBO(255, 255, 255, 1.00),

      shadows: [
        Shadow(
          blurRadius: 10.0, // Softness of the shadow
          color: Colors.black54, // Shadow color
          offset: Offset(4.0, 4.0), // X and Y displacement
        ),
      ],
    ),
    // Used for standard sub-headers and category titles
    headlineMedium: TextStyle(
      fontFamily: 'Abel',
      fontSize: 32,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Abel',
      fontWeight: FontWeight.w200,
      shadows: [
        Shadow(
          blurRadius: 10.0, // Softness of the shadow
          color: Colors.black54, // Shadow color
          offset: Offset(4.0, 4.0), // X and Y displacement
        ),
      ],
    ),
    // Used for the default main reading text block
    bodyLarge: TextStyle(
      fontFamily: 'Abel',
      fontSize: 16,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.5,
      shadows: [
        Shadow(
          blurRadius: 10.0, // Softness of the shadow
          color: Colors.black54, // Shadow color
          offset: Offset(4.0, 4.0), // X and Y displacement
        ),
      ],
    ),
    // Used for small components like captions or labels
    labelSmall: TextStyle(
      fontFamily: 'Abel',
      fontSize: 14,
      fontWeight: FontWeight.w700,
      shadows: [
        Shadow(
          blurRadius: 10.0, // Softness of the shadow
          color: Colors.black54, // Shadow color
          offset: Offset(4.0, 4.0), // X and Y displacement
        ),
      ],
    ),
    labelMedium: TextStyle(
      fontFamily: 'Abel',
      fontSize: 22,
      fontWeight: FontWeight.w300,
      shadows: [
        Shadow(
          blurRadius: 10.0, // Softness of the shadow
          color: Colors.black54, // Shadow color
          offset: Offset(4.0, 4.0), // X and Y displacement
        ),
      ],
    ),
    labelLarge: TextStyle(
      fontFamily: 'Abel',
      fontSize: 22,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          blurRadius: 10.0, // Softness of the shadow
          color: Colors.black54, // Shadow color
          offset: Offset(4.0, 4.0), // X and Y displacement
        ),
      ],
    ),
  );
}
