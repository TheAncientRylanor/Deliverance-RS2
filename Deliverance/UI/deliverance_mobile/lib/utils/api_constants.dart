class ApiConstants {
  static const String baseUrl = const String.fromEnvironment(
    "baseUrl",
    defaultValue: "http://10.0.2.2:5095/",
  );
}
