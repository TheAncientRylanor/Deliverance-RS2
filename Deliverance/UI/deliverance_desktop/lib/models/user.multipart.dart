import 'dart:io';
import 'package:http/http.dart' as http;

class UserMultipart {
  UserMultipart({
    this.uuid,
    this.firstName,
    this.lastName,
    this.email,
    this.username,
    this.roleId,
    this.profileImage,
  });
  final String? uuid;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? username;
  final int? roleId;
  final File? profileImage;

  Future<List<http.MultipartFile>> _toMultipartFiles() async {
    final files = <http.MultipartFile>[];
    if (profileImage != null) {
      files.add(
        await http.MultipartFile.fromPath('profileImage', profileImage!.path),
      );
    }
    return files;
  }

  Map<String, String> _toFormFields() {
    final fields = <String, String>{};
    if (uuid != null) fields['uuid'] = uuid!;
    if (firstName != null) fields['firstName'] = firstName!;
    if (lastName != null) fields['lastName'] = lastName!;
    if (email != null) fields['email'] = email!;
    if (username != null) fields['username'] = username!;
    if (roleId != null) fields['roleId'] = roleId!.toString();
    return fields;
  }

  Future<http.MultipartRequest> toMultipartRequest(
    String method,
    Uri uri,
  ) async {
    final request = http.MultipartRequest(method, uri)
      ..fields.addAll(_toFormFields())
      ..files.addAll(await _toMultipartFiles());
    return request;
  }
}
