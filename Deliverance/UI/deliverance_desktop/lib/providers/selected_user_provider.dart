import 'package:deliverance_desktop/models/user.dart';
import 'package:flutter/material.dart';

class SelectedUserProvider extends ChangeNotifier {
  User? _user;
  User? get user => _user;

  void select(User user) {
    _user = user;
    notifyListeners();
  }
}
