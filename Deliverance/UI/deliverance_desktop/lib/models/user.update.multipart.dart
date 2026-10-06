import 'dart:io';

import 'package:http/http.dart' as http;

class UserUpdateMultipart {
  UserUpdateMultipart({
    this.firstName,
    this.lastName,
    this.email,
    this.username,
    this.profileImage,
  });

  final String? firstName;
  final String? lastName;
  final String? email;
  final String? username;
  final File? profileImage;

  Future<http.MultipartRequest> toMultipartRequest(
    String method,
    Uri uri,
  ) async {
    final request = http.MultipartRequest(method, uri)
      ..fields['firstName'] = firstName!
      ..fields['lastName'] = lastName!
      ..fields['email'] = email!
      ..fields['username'] = username!;
    if (profileImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath('profileImage', profileImage!.path),
      );
    }
    return request;
  }
  /*
  Map<String, String> _toFormFields() {
    final fields = <String, String>{};
    if (firstName != null) fields['firstName'] = firstName!;
    if (lastName != null) fields['lastName'] = lastName!;
    if (email != null) fields['email'] = email!;
    if (username != null) fields['username'] = username!;
    return fields;
  }

  Future<List<http.MultipartFile>> _toMultipartFiles() async {
    final files = <http.MultipartFile>[];
    if (profileImage != null) {
      files.add(
        await http.MultipartFile.fromPath('profileImage', profileImage!.path),
      );
    }
    return files;
  }
  */
}
