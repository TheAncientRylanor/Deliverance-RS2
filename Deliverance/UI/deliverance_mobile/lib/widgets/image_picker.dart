import 'dart:io';

import 'package:image_picker/image_picker.dart';

Future<File?> pickImage(ImageSource source, ImagePicker picker) async {
  final XFile? pickedFile = await picker.pickImage(
    source: source,
    imageQuality: 80, // Optional compression (0-100)
    maxWidth: 1800, // Optional optimization resizing
  );

  if (pickedFile != null) {
    return File(pickedFile.path);
  }
  return null;
}
