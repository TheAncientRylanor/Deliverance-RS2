import 'dart:convert';
import 'package:deliverance_desktop/models/user.dart';
import 'package:deliverance_desktop/models/user.insert.multipart.dart';
import 'package:deliverance_desktop/models/user.update.multipart.dart';
import 'package:deliverance_desktop/providers/auth_provider.dart';
import 'package:deliverance_desktop/providers/base_provider.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

class UserProvider extends BaseProvider<User> {
  UserProvider() : super("User");

  @override
  User fromJson(data) {
    return User.fromJson(data);
  }

  Future<User?> loadCurrentUser() async {
    final token = AuthProvider.accesstoken;
    if (token == null || token.isEmpty) return null;
    final decodedToken = JwtDecoder.decode(token);
    final userId = decodedToken['nameid']?.toString();
    if (userId == null || userId.isEmpty) return null;
    return await getByUUID(userId);
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
    final response = await _sendMultipart(
      request.toMultipartRequest,
      "PUT",
      uri,
    );
    var data = jsonDecode(response.body);
    final user = fromJson(data);
    setData(user);
    return user;
  }

  Future<User> insertUser(UserInsertRequest request) async {
    var baseURL = BaseProvider.baseUrl;
    var url = "$baseURL$endpoint/InsertUser";
    var uri = Uri.parse(url);
    final response = await _sendMultipart(
      request.toMultipartRequest,
      "POST",
      uri,
    );
    var data = jsonDecode(response.body);
    final user = fromJson(data);
    setData(user);
    return user;
  }

  Future<http.Response> _sendMultipart(
    Future<http.MultipartRequest> Function(String method, Uri uri) build,
    String method,
    Uri uri,
  ) {
    return sendWithRetry(() async {
      final multiPartRequest = await build(method, uri);
      multiPartRequest.headers['Authorization'] =
          'Bearer ${AuthProvider.accesstoken}';
      final streamedResponse = await multiPartRequest.send();
      return http.Response.fromStream(streamedResponse);
    });
  }

  Future<bool> userNameExist(String username) async {
    final response = await sendWithRetry(() async {
      var baseURL = BaseProvider.baseUrl;
      var url =
          "$baseURL$endpoint/CheckUsername?request=${Uri.encodeQueryComponent(username)}";
      var uri = Uri.parse(url);
      var headers = createHeaders();
      return await http.post(uri, headers: headers);
    });
    var data = jsonDecode(response.body);
    return data;
  }
}
