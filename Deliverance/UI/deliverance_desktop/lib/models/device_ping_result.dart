class DevicePingResult {
  final bool isOnline;
  final int? roundtripMs;

  DevicePingResult({required this.isOnline, this.roundtripMs});

  factory DevicePingResult.fromJson(Map<String, dynamic> json) =>
      DevicePingResult(
        isOnline: json['isOnline'] as bool,
        roundtripMs: (json['roundtripMs'] as num?)?.toInt(),
      );
}
