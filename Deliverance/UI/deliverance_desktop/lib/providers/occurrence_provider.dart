import 'package:deliverance_desktop/models/occurrence.dart';
import 'package:deliverance_desktop/providers/base_provider.dart';

class OccurrenceProvider extends BaseProvider<Occurrence> {
  OccurrenceProvider() : super("Occurrence");
  @override
  Occurrence fromJson(data) {
    return Occurrence.fromJson(data);
  }
}
