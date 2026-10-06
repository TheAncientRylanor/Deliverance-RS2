// ignore_for_file: file_names

import 'package:flutter/material.dart';

class GlobalData extends ChangeNotifier {
  String lastScreenName = "home";
  void updateWidget(String title) {
    lastScreenName = title;
    notifyListeners();
  }
}
