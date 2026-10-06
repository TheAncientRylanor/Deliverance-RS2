import 'package:deliverance_desktop/models/report.dart';
import 'package:flutter/material.dart';

class SelectedReportProvider extends ChangeNotifier {
  Report? _report;
  Report? get report => _report;

  void select(Report report) {
    _report = report;
    notifyListeners();
  }
}
