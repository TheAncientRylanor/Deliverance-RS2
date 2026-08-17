import 'package:deliverance_mobile/models/office.dart';
import 'package:deliverance_mobile/providers/base_provider.dart';

class OfficeProvider extends BaseProvider<Office> {
  OfficeProvider() : super("Office");
  @override
  Office fromJson(data) {
    return Office.fromJson(data);
  }
}
