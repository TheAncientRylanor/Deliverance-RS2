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
  positionX: (json['positionX'] as num?)?.toDouble(),
  positionY: (json['positionY'] as num?)?.toDouble(),
  type: json['type'] as String?,
  manufacturer: json['manufacturer'] as String?,
);

Map<String, dynamic> _$DevicesToJson(Devices instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'positionX': instance.positionX,
  'positionY': instance.positionY,
  'type': instance.type,
  'manufacturer': instance.manufacturer,
};
