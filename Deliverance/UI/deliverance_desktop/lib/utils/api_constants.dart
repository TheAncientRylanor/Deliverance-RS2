class ApiConstants {
  static const String baseUrl = const String.fromEnvironment(
    "baseUrl",
    defaultValue: "http://localhost:5095/",
  );
}
