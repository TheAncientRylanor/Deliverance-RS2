class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    "baseUrl",
    defaultValue: "http://10.0.2.2:5095/",
  );
  static const Duration authRequestTimeout = Duration(seconds: 10);
}
