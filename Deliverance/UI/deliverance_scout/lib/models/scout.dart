class Scout {
  final int id;
  final int deviceId;
  final String deviceName;
  final int officeId;
  final String officeName;

  Scout({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.officeId,
    required this.officeName,
  });

  factory Scout.fromJson(Map<String, dynamic> json) => Scout(
    id: json['id'] as int,
    deviceId: json['deviceId'] as int,
    deviceName: json['deviceName'] as String,
    officeId: json['officeId'] as int,
    officeName: json['officeName'] as String,
  );
}
