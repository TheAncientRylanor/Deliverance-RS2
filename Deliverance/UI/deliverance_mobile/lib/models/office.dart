import 'package:json_annotation/json_annotation.dart';

part 'office.g.dart';
@JsonSerializable()
class Office {
  final int? id;
  final String? name;
  final List<Devices>? devices;
  Office({
    this.id,
    this.name,
    this.devices,
  });
  factory Office.fromJson(Map<String, dynamic> json) =>
      _$OfficeFromJson(json);

  Map<String, dynamic> toJson() => _$OfficeToJson(this);
}

@JsonSerializable()
class Devices{
  final int? id;
  final String? name;
  final String? officeName;
  final int? officeId;
  final double? positionX;
  final double? positionY;
  final String? iconName;
  final String? type;
  final String? ipAddress;
  final String? macAddress;
  final String? subnetMask;
  final String? vlanID;
  final String? os;
  final String? manufacturer;

  Devices({ this.id,  this.name,  this.officeName,  this.officeId,  this.positionX,  this.positionY,  this.iconName,  this.type,  this.ipAddress,  this.macAddress,  this.subnetMask,  this.vlanID,  this.os,  this.manufacturer});

  factory Devices.fromJson(Map<String, dynamic> json) =>
      _$DevicesFromJson(json);

  Map<String, dynamic> toJson() => _$DevicesToJson(this);
}