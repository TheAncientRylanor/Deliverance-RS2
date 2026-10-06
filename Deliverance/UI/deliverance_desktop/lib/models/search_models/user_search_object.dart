import 'package:deliverance_desktop/models/base_search_object.dart';

class UserSearchObject extends BaseSearchObject {
  String? email;
  String? username;
  DateTime? createdAt;

  UserSearchObject({
    super.page,
    super.pageSize,
    super.includeTotalCount,
    super.sortBy = "CreatedAt",
    super.descending = true,
  });

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    if (email != null && email!.isNotEmpty) {
      map['Email'] = email;
    }
    if (username != null) map['Username'] = username;
    if (createdAt != null) map['CreatedAt'] = createdAt;
    return map;
  }
}
