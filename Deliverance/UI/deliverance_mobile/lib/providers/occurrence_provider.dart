import 'package:deliverance_mobile/models/occurrence.dart';
import 'package:deliverance_mobile/providers/base_provider.dart';

class OccurrenceProvider extends BaseProvider<Occurrence> {
  OccurrenceProvider() : super("Occurrence");
  @override
  Occurrence fromJson(data) {
    return Occurrence.fromJson(data);
  }
}
