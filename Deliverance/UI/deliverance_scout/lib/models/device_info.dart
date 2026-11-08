class DeviceInfo {
  final String? ipAddress;
  final String? subnetMask;
  final String? macAddress;
  final String? os;
  final String? manufacturer;
  final String? hostname;

  DeviceInfo({
    this.ipAddress,
    this.subnetMask,
    this.macAddress,
    this.os,
    this.manufacturer,
    this.hostname,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) => DeviceInfo(
    ipAddress: json['ipAddress'] as String?,
    subnetMask: json['subnetMask'] as String?,
    macAddress: json['macAddress'] as String?,
    os: json['os'] as String?,
    manufacturer: json['manufacturer'] as String?,
    hostname: json['hostname'] as String?,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'ipAddress': ipAddress,
    'subnetMask': subnetMask,
    'macAddress': macAddress,
    'os': os,
    'manufacturer': manufacturer,
    'hostname': hostname,
  };
}
