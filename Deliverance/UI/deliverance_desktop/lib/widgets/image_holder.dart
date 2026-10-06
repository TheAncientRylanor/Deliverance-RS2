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

      // Decode images close to their on-screen size instead of at full
      // resolution. The box is 2x the display size so BoxFit.cover still has
      // enough pixels on the short side for landscape/portrait photos.
      final displaySize = finiteSizes.isEmpty
          ? 200.0
          : finiteSizes.reduce(math.max);
      final decodeSize =
          (displaySize * MediaQuery.devicePixelRatioOf(context) * 2).round();
      ImageProvider resized(ImageProvider provider) => ResizeImage(
        provider,
        width: decodeSize,
        height: decodeSize,
        policy: ResizeImagePolicy.fit,
      );

      if (selectedImage != null) {
        return Center(
          child: Image(
            image: resized(FileImage(selectedImage)),
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
        child: Image(
          image: resized(NetworkImage('$baseUrl$imagePath')),
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
