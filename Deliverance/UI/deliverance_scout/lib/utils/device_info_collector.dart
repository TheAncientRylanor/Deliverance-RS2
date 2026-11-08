import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:deliverance_scout/models/device_info.dart';

const bool fakeNetwork = bool.fromEnvironment('fakeNetwork');

abstract class DeviceInfoCollector {
  Future<DeviceInfo> collect();

  factory DeviceInfoCollector() =>
      fakeNetwork ? FakeDeviceInfoCollector() : WindowsDeviceInfoCollector();
}

class WindowsDeviceInfoCollector implements DeviceInfoCollector {
  static const _script = r'''
$adapters = @(Get-CimInstance Win32_NetworkAdapterConfiguration -Filter 'IPEnabled=true')
$adapter = $adapters | Where-Object { $_.DefaultIPGateway } | Select-Object -First 1
if (-not $adapter) { $adapter = $adapters | Select-Object -First 1 }
$ip = $null; $mask = $null
if ($adapter) {
  for ($i = 0; $i -lt $adapter.IPAddress.Count; $i++) {
    if ($adapter.IPAddress[$i] -match '^\d+\.\d+\.\d+\.\d+$') { $ip = $adapter.IPAddress[$i]; $mask = $adapter.IPSubnet[$i]; break }
  }
}
$cs = Get-CimInstance Win32_ComputerSystem
$os = Get-CimInstance Win32_OperatingSystem
[pscustomobject]@{
  ipAddress = $ip; subnetMask = $mask; macAddress = $adapter.MACAddress
  os = "$($os.Caption) $($os.Version)".Trim()
  manufacturer = $cs.Manufacturer
  hostname = $env:COMPUTERNAME
} | ConvertTo-Json -Compress
''';

  static const _maxOsLength = 50;
  static const _maxManufacturerLength = 50;

  @override
  Future<DeviceInfo> collect() async {
    final result = await Process.run('powershell', [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      _script,
    ]);
    if (result.exitCode != 0) {
      throw Exception(
        "Could not read the device information: ${result.stderr}",
      );
    }

    final info = DeviceInfo.fromJson(
      jsonDecode(result.stdout as String) as Map<String, dynamic>,
    );
    return DeviceInfo(
      ipAddress: info.ipAddress,
      subnetMask: info.subnetMask,
      macAddress: info.macAddress,
      os: _truncate(info.os, _maxOsLength),
      manufacturer: _truncate(info.manufacturer, _maxManufacturerLength),
      hostname: info.hostname,
    );
  }

  static String? _truncate(String? value, int maxLength) =>
      value == null || value.length <= maxLength
      ? value
      : value.substring(0, maxLength);
}

class FakeDeviceInfoCollector implements DeviceInfoCollector {
  final _real = WindowsDeviceInfoCollector();
  final _random = Random.secure();

  @override
  Future<DeviceInfo> collect() async {
    final real = await _real.collect();
    return DeviceInfo(
      ipAddress: '192.168.50.${2 + _random.nextInt(250)}',
      subnetMask: '255.255.255.0',
      macAddress: _randomMac(),
      os: real.os,
      manufacturer: real.manufacturer,
      hostname: real.hostname,
    );
  }

  String _randomMac() {
    final bytes = List.generate(6, (_) => _random.nextInt(256));
    bytes[0] = (bytes[0] & 0xFC) | 0x02;
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
  }
}
