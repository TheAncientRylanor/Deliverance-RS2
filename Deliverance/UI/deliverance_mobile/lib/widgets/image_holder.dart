import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

Widget buildProfileImage(
  File? selectedImage,
  String? imagePath,
  String baseUrl, {
  double? width,
  double? height,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final resolvedWidth = width ?? constraints.maxWidth;
      final resolvedHeight = height ?? constraints.maxHeight;
      final finiteSizes = [
        resolvedWidth,
        resolvedHeight,
      ].where((s) => s.isFinite);
      final iconSize = finiteSizes.isEmpty
          ? 200.0
          : finiteSizes.reduce(math.min);

      if (selectedImage != null) {
        return Center(
          child: Image.file(
            selectedImage,
            fit: BoxFit.cover,
            width: resolvedWidth,
            height: resolvedHeight,
          ),
        );
      }
      if (imagePath == null || imagePath.isEmpty) {
        return Center(
          child: Icon(Icons.person, size: iconSize, color: Colors.grey),
        );
      }

      return Center(
        child: Image.network(
          '$baseUrl$imagePath',
          fit: BoxFit.cover,
          width: resolvedWidth,
          height: resolvedHeight,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.person, size: iconSize, color: Colors.grey),
        ),
      );
    },
  );
}
