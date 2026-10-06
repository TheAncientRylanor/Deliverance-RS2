import 'dart:io';

import 'package:http/http.dart' as http;

class UserInsertRequest {
  UserInsertRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    required this.password,
    this.profileImage,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final String password;
  final File? profileImage;

  Future<http.MultipartRequest> toMultipartRequest(
    String method,
    Uri uri,
  ) async {
    final request = http.MultipartRequest(method, uri)
      ..fields['firstName'] = firstName
      ..fields['lastName'] = lastName
      ..fields['email'] = email
      ..fields['username'] = username
      ..fields['password'] = password;
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
    fields['firstName'] = firstName;
    fields['lastName'] = lastName;
    fields['email'] = email;
    fields['username'] = username;
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
