import 'package:deliverance_desktop/models/base_search_object.dart';
import 'package:deliverance_desktop/models/report_status_filter.dart';

class ReportSearchObject extends BaseSearchObject {
  String? reportName;
  int? deviceId;
  int? officeId;
  String? userId;
  ReportStatusFilter? status;
  ReportSearchObject({
    this.reportName,
    this.deviceId,
    this.officeId,
    this.userId,
    this.status,
    super.page,
    super.pageSize,
    super.includeTotalCount,
    super.sortBy = "Status",
    super.descending = true,
  });

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    if (reportName != null && reportName!.isNotEmpty) {
      map['ReportName'] = reportName;
    }
    if (deviceId != null) map['DeviceId'] = deviceId;
    if (officeId != null) map['OfficeId'] = officeId;
    if (userId != null) map['UserId'] = userId;
    if (status != null) map['Status'] = status!.value;
    return map;
  }
}
