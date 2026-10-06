import 'package:deliverance_mobile/models/occurance.dart';
import 'package:deliverance_mobile/providers/base_provider.dart';

class OccuranceProvider extends BaseProvider<Occurance> {
  OccuranceProvider() : super("Occurance");
  @override
  Occurance fromJson(data) {
    return Occurance.fromJson(data);
  }
}
