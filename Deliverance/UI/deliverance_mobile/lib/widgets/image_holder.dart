import 'dart:io';

import 'package:flutter/material.dart';

Widget buildProfileImage(
  File? selectedImage,
  String? imagePath,
  String baseUrl, {
  int width = 240,
  int height = 240,
}) {
  if (selectedImage != null) {
    return Image.file(
      selectedImage!,
      fit: BoxFit.cover,
      width: 240,
      height: 240,
    );
  }
  if (imagePath == null || imagePath.isEmpty) {
    return const Icon(Icons.person, size: 200, color: Colors.grey);
  }

  return Image.network(
    '$baseUrl$imagePath',
    fit: BoxFit.cover,
    width: 240,
    height: 240,
    errorBuilder: (context, error, stackTrace) =>
        const Icon(Icons.person, size: 240, color: Colors.grey),
  );
}
