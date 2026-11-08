class ApiConstants {
  /// Set on the command line: flutter run --dart-define=API_BASE_URL=http://localhost:5095/
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: "http://10.0.2.2:5095/",
  );
  static const Duration authRequestTimeout = Duration(seconds: 10);
}
