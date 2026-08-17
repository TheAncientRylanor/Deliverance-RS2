part of 'office.dart';

Office _$OfficeFromJson(Map<String, dynamic> json) => Office(
  id: json['id'] as int?,
  name: json['name'] as String?,
  devices: (json['devices'] as List<dynamic>?)
      ?.map((e) => Devices.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$OfficeToJson(Office instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'devices': instance.devices?.map((e) => e.toJson()).toList(),
};

Devices _$DevicesFromJson(Map<String, dynamic> json) => Devices(
  id: json['id'] as int?,
  name: json['name'] as String?,
  officeName: json['officeName'] as String?,
  officeId: json['officeId'] as int?,
  positionX: (json['positionX'] as num?)?.toDouble(),
  positionY: (json['positionY'] as num?)?.toDouble(),
  iconName: json['iconName'] as String?,
  type: json['type'] as String?,
  ipAddress: json['ipAddress'] as String?,
  macAddress: json['macAddress'] as String?,
  subnetMask: json['subnetMask'] as String?,
  vlanID: json['vlanID'] as String?,
  os: json['os'] as String?,
  manufacturer: json['manufacturer'] as String?,
);

Map<String, dynamic> _$DevicesToJson(Devices instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'officeName': instance.officeName,
  'officeId': instance.officeId,
  'positionX': instance.positionX,
  'positionY': instance.positionY,
  'iconName': instance.iconName,
  'type': instance.type,
  'ipAddress': instance.ipAddress,
  'macAddress': instance.macAddress,
  'subnetMask': instance.subnetMask,
  'vlanID': instance.vlanID,
  'os': instance.os,
  'manufacturer': instance.manufacturer,
};
