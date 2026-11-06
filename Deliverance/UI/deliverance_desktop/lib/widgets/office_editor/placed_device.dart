import 'package:deliverance_desktop/models/office.dart';
import 'package:flutter/material.dart';

/// The details of a device that the user fills in through the device dialog.
class DeviceDetails {
  final String? name;
  final String? ipAddress;
  final String? subnetMask;
  final String? vlanID;
  final String? os;
  final String? manufacturer;
  final String? macAddress;
  // Set once a scout has claimed this device's enrollment token. Sent on save
  // so the backend links the scout to the device.
  final int? enrollmentId;

  const DeviceDetails({
    this.name,
    this.ipAddress,
    this.subnetMask,
    this.vlanID,
    this.os,
    this.manufacturer,
    this.macAddress,
    this.enrollmentId,
  });

  /// Trims [value] and turns empty strings into null, so an untouched field
  /// and a cleared one compare equal and are sent to the API the same way.
  static String? clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  @override
  bool operator ==(Object other) =>
      other is DeviceDetails &&
      other.name == name &&
      other.ipAddress == ipAddress &&
      other.subnetMask == subnetMask &&
      other.vlanID == vlanID &&
      other.os == os &&
      other.manufacturer == manufacturer &&
      other.macAddress == macAddress &&
      other.enrollmentId == enrollmentId;

  @override
  int get hashCode => Object.hash(
    name,
    ipAddress,
    subnetMask,
    vlanID,
    os,
    manufacturer,
    macAddress,
    enrollmentId,
  );
}

/// A device placed on the office editor canvas.
class PlacedDevice {
  // Null until the office has been saved with this device in it.
  final int? id;
  final String type;
  // Top-left corner as a fraction (0..1) of the canvas size, so the layout
  // scales with the window.
  Offset position;
  DeviceDetails details;
  // Null when no scout is installed on the device.
  Scout? scout;

  PlacedDevice({
    this.id,
    required this.type,
    required this.position,
    this.details = const DeviceDetails(),
    this.scout,
  });

  factory PlacedDevice.fromDevice(Devices device) => PlacedDevice(
    id: device.id,
    type: device.type ?? "",
    position: Offset(device.positionX ?? 0, device.positionY ?? 0),
    scout: device.scout,
    details: DeviceDetails(
      name: DeviceDetails.clean(device.name),
      ipAddress: DeviceDetails.clean(device.ipAddress),
      subnetMask: DeviceDetails.clean(device.subnetMask),
      vlanID: DeviceDetails.clean(device.vlanID),
      os: DeviceDetails.clean(device.os),
      manufacturer: DeviceDetails.clean(device.manufacturer),
      macAddress: DeviceDetails.clean(device.macAddress),
    ),
  );

  /// The device as it is sent to the API when saving [officeName].
  Devices toDevice(String officeName) => Devices(
    // New devices are sent with id 0.
    id: id ?? 0,
    name: details.name,
    officeName: officeName,
    positionX: position.dx,
    positionY: position.dy,
    iconName: type.toLowerCase(),
    type: type,
    ipAddress: details.ipAddress,
    macAddress: details.macAddress,
    subnetMask: details.subnetMask,
    vlanID: details.vlanID,
    os: details.os,
    manufacturer: details.manufacturer,
    enrollmentId: details.enrollmentId,
  );
}
