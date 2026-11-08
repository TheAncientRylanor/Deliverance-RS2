final _ipv4 = RegExp(
  r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}'
  r'(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
);
final _mac = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$');

bool _isEmpty(String? value) => value == null || value.trim().isEmpty;

String? validateOfficeName(String? value) {
  final name = value?.trim() ?? "";
  if (name.isEmpty) return "Office name is required";
  if (name.length < 2 || name.length > 20) {
    return "Office name must be 2 to 20 characters long";
  }
  return null;
}

String? validateDeviceName(String? value) {
  final name = value?.trim() ?? "";
  if (name.isEmpty) return "Device name is required";
  if (name.length < 2 || name.length > 50) {
    return "Device name must be 2 to 50 characters long";
  }
  return null;
}

String? validateIpAddress(String? value) {
  if (_isEmpty(value) || _ipv4.hasMatch(value!.trim())) return null;
  return "Enter an IPv4 address: four numbers from 0 to 255 separated by dots (e.g. 192.168.1.1)";
}

String? validateSubnetMask(String? value) {
  if (_isEmpty(value)) return null;
  final mask = value!.trim();
  if (!_ipv4.hasMatch(mask)) {
    return "Enter a subnet mask: four numbers from 0 to 255 separated by dots (e.g. 255.255.255.0)";
  }
  final bits = mask
      .split('.')
      .fold(0, (acc, octet) => (acc << 8) | int.parse(octet));
  final inverted = ~bits & 0xFFFFFFFF;
  if ((inverted & (inverted + 1)) != 0) {
    return "Subnet mask bits must be contiguous (e.g. 255.255.255.0)";
  }
  return null;
}

String? validateVlanId(String? value) {
  if (_isEmpty(value)) return null;
  final id = int.tryParse(value!.trim());
  if (id != null && id >= 1 && id <= 4094) return null;
  return "VLAN ID must be a number between 1 and 4094";
}

String? validateMacAddress(String? value) {
  if (_isEmpty(value) || _mac.hasMatch(value!.trim())) return null;
  return "Enter a MAC address: six pairs of hex digits separated by : or - (e.g. 00:1A:2B:3C:4D:5E)";
}

String? validateMaxLength50(String? value, [String label = "This field"]) {
  if ((value?.trim().length ?? 0) <= 50) return null;
  return "$label can have at most 50 characters";
}
