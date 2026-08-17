import 'package:flutter/material.dart';

class CustomTextEditingController extends TextEditingController {
  final int? customKey;

  CustomTextEditingController({String? text, this.customKey})
    : super(text: text);
}
