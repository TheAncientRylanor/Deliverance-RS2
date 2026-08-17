import 'package:deliverance_mobile/models/report.dart';
import 'package:deliverance_mobile/providers/base_provider.dart';

class ReportProvider extends BaseProvider<Report> {
  ReportProvider() : super("Report");
  @override
  Report fromJson(data) {
    return Report.fromJson(data);
  }
}
