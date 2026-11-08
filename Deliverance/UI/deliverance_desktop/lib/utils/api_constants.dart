class ApiConstants {
  /// Set on the command line: flutter run --dart-define=API_BASE_URL=http://localhost:5095/
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: "http://localhost:5095/",
  );
}
