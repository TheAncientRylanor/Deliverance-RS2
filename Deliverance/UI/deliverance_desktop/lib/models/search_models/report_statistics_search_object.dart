import 'package:deliverance_desktop/models/base_search_object.dart';

class ReportStatisticsSearchObject extends BaseSearchObject {
  int? officeId;
  DateTime? reportDate;
  ReportStatisticsSearchObject({
    this.officeId,
    super.page,
    super.pageSize,
    super.includeTotalCount,
    super.sortBy,
    super.descending,
  });

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    if (officeId != null) map['OfficeId'] = officeId;
    if (reportDate != null) map['ReportDate'] = reportDate;
    return map;
  }
}
