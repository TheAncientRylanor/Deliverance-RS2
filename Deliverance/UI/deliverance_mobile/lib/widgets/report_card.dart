import 'package:deliverance_mobile/models/report.dart';
import 'package:deliverance_mobile/models/severity_enum.dart';
import 'package:deliverance_mobile/screens/report_details_screen.dart';
import 'package:deliverance_mobile/screens/report_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback initFunction;
  const ReportCard({
    super.key,
    required this.report,
    required this.initFunction,
  });

  String _getOfficeNames(List<OfficeReport> officeReports) {
    return officeReports.map((x) => x.name).join('; ');
  }

  bool get _isUnseen => report.status == "UnseenReportState";
  bool get _isEditable => report.status == "DraftReportState" || _isUnseen;

  Widget? _buildStatusIcon(BuildContext context) {
    if (report.status == "DraftReportState") {
      return Icon(
        Icons.edit,
        color: Theme.of(context).colorScheme.primary,
        size: 22,
      );
    }
    if (report.status == "ClearedReportState") {
      return Icon(
        Icons.done_all,
        color: Theme.of(context).colorScheme.primary,
        size: 22,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,
      shadowColor: Colors.black,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              border: _isUnseen
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
              borderRadius: BorderRadius.circular(5),
            ),
            width: double.infinity,
            height: 140,
            child: Row(
              children: [
                Expanded(
                  flex: 7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          color: Theme.of(context).colorScheme.surfaceDim,
                          child: Row(
                            spacing: 5,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 25,
                                color: Colors.white,
                              ),
                              Expanded(
                                child: Text(
                                  "Location: ${_getOfficeNames(report.officeReports ?? [])}",
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(fontWeight: FontWeight(100)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          child: Row(
                            spacing: 5,
                            children: [
                              Icon(Icons.close, size: 25, color: Colors.white),
                              Expanded(
                                child: Text(
                                  "Problem: ${report.reportName}",
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(fontWeight: FontWeight(100)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: Theme.of(context).colorScheme.surfaceDim,
                          child: Row(
                            spacing: 5,
                            children: [
                              Icon(
                                Icons.linear_scale,
                                size: 25,
                                color: Colors.white,
                              ),
                              Expanded(
                                child: Text(
                                  "Severity: ${SeverityEnum.fromValue(report.severity ?? 1).label}",
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(fontWeight: FontWeight(100)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          child: Row(
                            spacing: 5,
                            children: [
                              Icon(
                                Icons.date_range,
                                size: 25,
                                color: Colors.white,
                              ),
                              Expanded(
                                child: Text(
                                  "Date sent: ${DateFormat('yyyy-MM-dd').format(report.dateReported)}",
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(fontWeight: FontWeight(100)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    height: double.infinity,
                    color: Theme.of(context).colorScheme.secondary,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => _isEditable
                                    ? ReportScreen(report: report)
                                    : ReportDetailsScreen(report: report),
                              ),
                            );
                            initFunction();
                          },
                          icon: Icon(
                            Icons.arrow_forward_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 45,
                          ),
                        ),
                        Text(
                          "GO",
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_buildStatusIcon(context) != null)
            Positioned(top: 8, right: 8, child: _buildStatusIcon(context)!),
          if (_isUnseen)
            Positioned(
              top: -7,
              right: -7,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
