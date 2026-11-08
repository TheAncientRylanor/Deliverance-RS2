class SystemInfo {
  final String? os;
  final DateTime? lastOsUpdate;

  SystemInfo({this.os, this.lastOsUpdate});

  factory SystemInfo.fromJson(Map<String, dynamic> json) => SystemInfo(
    os: json['os'] as String?,
    lastOsUpdate: json['lastOsUpdate'] == null
        ? null
        : DateTime.parse(json['lastOsUpdate'] as String),
  );

  Map<String, dynamic> toJson() => {
    'os': os,
    'lastOsUpdate': lastOsUpdate?.toUtc().toIso8601String(),
  };
}
