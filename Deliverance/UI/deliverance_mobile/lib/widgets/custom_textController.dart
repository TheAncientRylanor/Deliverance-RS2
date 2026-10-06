// ignore_for_file: file_names

import 'package:flutter/material.dart';

class CustomTextEditingController extends TextEditingController {
  final int? customKey;

  CustomTextEditingController({super.text, this.customKey});
}
