import 'package:deliverance_desktop/models/office.dart';
import 'package:deliverance_desktop/providers/base_provider.dart';

class OfficeProvider extends BaseProvider<Office> {
  OfficeProvider() : super("Office");
  @override
  Office fromJson(data) {
    return Office.fromJson(data);
  }
}
