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
    var baseURL = BaseProvider.baseUrl;
    var url = "$baseURL$endpoint/UpdateUser/$id";
    var uri = Uri.parse(url);
    final multiPartRequest = await request.toMultipartRequest("PUT", uri);
    multiPartRequest.headers['Authorization'] =
        'Bearer ${AuthProvider.accesstoken}';
    final streamedResponse = await multiPartRequest.send();
    final response = await http.Response.fromStream(streamedResponse);
    validateResponse(response);
    var data = jsonDecode(response.body);
    final user = fromJson(data);
    setData(user);
    return user;
  }

  Future<User> insertUser(UserInsertRequest request) async {
    var baseURL = BaseProvider.baseUrl;
    var url = "$baseURL$endpoint/InsertUser";
    var uri = Uri.parse(url);
    final multiPartRequest = await request.toMultipartRequest("POST", uri);
    multiPartRequest.headers['Authorization'] =
        'Bearer ${AuthProvider.accesstoken}';
    final streamedResponse = await multiPartRequest.send();
    final response = await http.Response.fromStream(streamedResponse);
    validateResponse(response);
    var data = jsonDecode(response.body);
    final user = fromJson(data);
    setData(user);
    return user;
  }
}
