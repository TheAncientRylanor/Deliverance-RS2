class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    "baseUrl",
    defaultValue: "http://localhost:5095/",
  );
}
