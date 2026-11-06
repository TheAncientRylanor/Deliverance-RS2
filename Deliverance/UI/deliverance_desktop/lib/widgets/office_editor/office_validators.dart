// Client-side copies of the API's office and device validators
// (Deliverance.Services/Validators), so mistakes are shown on the field
// instead of as one error when the whole office is saved.

final _ipv4 = RegExp(
  r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}'
  r'(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
);
final _mac = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$');

bool _isEmpty(String? value) => value == null || value.trim().isEmpty;

String? validateOfficeName(String? value) {
  final name = value?.trim() ?? "";
  if (name.isEmpty) return "Office name is required";
  if (name.length < 3) return "Office name must be at least 3 characters";
  if (name.length > 20) return "Office name can be at most 20 characters";
  return null;
}

String? validateDeviceName(String? value) {
  final name = value?.trim() ?? "";
  if (name.isEmpty) return "Device name is required";
  if (name.length < 2) return "Device name must be at least 2 characters";
  if (name.length > 50) return "Device name can be at most 50 characters";
  return null;
}

String? validateIpAddress(String? value) {
  if (_isEmpty(value) || _ipv4.hasMatch(value!.trim())) return null;
  return "Must be a valid IPv4 address (e.g. 192.168.1.1)";
}

String? validateSubnetMask(String? value) {
  if (_isEmpty(value)) return null;
  final mask = value!.trim();
  if (!_ipv4.hasMatch(mask)) {
    return "Must be a valid subnet mask (e.g. 255.255.255.0)";
  }
  final bits = mask
      .split('.')
      .fold(0, (acc, octet) => (acc << 8) | int.parse(octet));
  // A valid mask is all ones followed by all zeros, so its inverse is a
  // block of low ones, and adding 1 to that clears every bit.
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
  return "Must be a valid MAC address (e.g. 00:1A:2B:3C:4D:5E)";
}

String? validateMaxLength50(String? value) {
  if ((value?.trim().length ?? 0) <= 50) return null;
  return "Can be at most 50 characters";
}
