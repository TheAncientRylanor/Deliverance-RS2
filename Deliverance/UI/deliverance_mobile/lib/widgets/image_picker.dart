import 'dart:io';

import 'package:image_picker/image_picker.dart';

Future<File?> pickImage(ImageSource source, ImagePicker picker) async {
  final XFile? pickedFile = await picker.pickImage(
    source: source,
    imageQuality: 80,
    maxWidth: 1800,
  );

  if (pickedFile != null) {
    return File(pickedFile.path);
  }
  return null;
}
