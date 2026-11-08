import 'dart:convert';
import 'package:deliverance_mobile/models/user.dart';
import 'package:deliverance_mobile/models/user.insert.multipart.dart';
import 'package:deliverance_mobile/models/user.update.multipart.dart';
import 'package:deliverance_mobile/providers/auth_provider.dart';
import 'package:deliverance_mobile/providers/base_provider.dart';
import 'package:http/http.dart' as http;

class UserProvider extends BaseProvider<User> {
  UserProvider() : super("User");

  @override
  User fromJson(data) {
    return User.fromJson(data);
  }

  Future<User> getByUUID(String id) async {
    final response = await sendWithRetry(() async {
      var baseURL = BaseProvider.baseUrl;
      var url = "$baseURL$endpoint/UUID/$id";
      var uri = Uri.parse(url);
      var headers = createHeaders();
      return await http.get(uri, headers: headers);
    });
    var data = jsonDecode(response.body);
    final parsed = fromJson(data);
    setData(parsed);
    return parsed;
  }

  Future<User> updateUser(String id, UserUpdateMultipart request) async {
    var url = "${BaseProvider.baseUrl}$endpoint/UpdateUser/$id";
    var uri = Uri.parse(url);
    final response = await sendWithRetry(() async {
      final multiPartRequest = await request.toMultipartRequest("PUT", uri);
      multiPartRequest.headers['Authorization'] =
          'Bearer ${AuthProvider.accesstoken}';
      final streamedResponse = await multiPartRequest.send();
      return http.Response.fromStream(streamedResponse);
    });
    var data = jsonDecode(response.body);
    final user = fromJson(data);
    setData(user);
    return user;
  }

  Future<User> insertUser(UserInsertRequest request) async {
    var uri = Uri.parse("${BaseProvider.baseUrl}Access/Register");
    final multiPartRequest = await request.toMultipartRequest("POST", uri);
    final streamedResponse = await multiPartRequest.send();
    final response = await http.Response.fromStream(streamedResponse);
    validateResponse(response);
    var data = jsonDecode(response.body);
    final user = fromJson(data);
    setData(user);
    return user;
  }

  Future<bool> userNameExist(String username) async {
    final response = await sendWithRetry(() async {
      var baseURL = BaseProvider.baseUrl;
      var url =
          "${baseURL}Access/Register/CheckUsername?username=${Uri.encodeQueryComponent(username)}";
      var uri = Uri.parse(url);
      var headers = createHeaders();
      return await http.get(uri, headers: headers);
    });
    var data = jsonDecode(response.body);
    return data;
  }
}
