import 'package:deliverance_desktop/models/office.dart';
import 'package:deliverance_desktop/models/report.dart';
import 'package:deliverance_desktop/models/report_status_filter.dart';
import 'package:deliverance_desktop/models/search_models/report_search_object.dart';
import 'package:deliverance_desktop/models/search_result.dart';
import 'package:deliverance_desktop/providers/report_provider.dart';
import 'package:deliverance_desktop/utils/api_client_exception.dart';
import 'package:deliverance_desktop/utils/util_widgets.dart';
import 'package:deliverance_desktop/widgets/custom_buttons.dart';
import 'package:deliverance_desktop/widgets/custom_drop_down.dart';
import 'package:deliverance_desktop/widgets/custom_text_field.dart';
import 'package:deliverance_desktop/widgets/reports_child.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SingleDeviceReportScreen extends StatefulWidget {
  final Devices device;
  final String officeName;
  const SingleDeviceReportScreen({
    super.key,
    required this.device,
    required this.officeName,
  });

  @override
  State<SingleDeviceReportScreen> createState() =>
      _SingleDeviceReportScreenState();
}

class _SingleDeviceReportScreenState extends State<SingleDeviceReportScreen> {
  late ReportProvider _reportProvider;
  final TextEditingController _commandController = TextEditingController();
  ReportSearchObject searchObject = ReportSearchObject(
    status: ReportStatusFilter.active,
  );
  SearchResult<Report> reportList = SearchResult();
  bool isLoading = false;
  TableRow _buildRow(
    BuildContext context,
    String label,
    String value, {
    PrimaryButton? button,
  }) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium;
    return TableRow(
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainer),
      children: [
        TableCell(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 8.0,
              bottom: 8.0,
              right: 8,
              left: 20,
            ),
            child: Text(
              textDirection: TextDirection.rtl,
              label,
              style: style?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: button == null
                ? Text(value, style: style)
                : Align(alignment: Alignment.centerLeft, child: button),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _reportProvider = context.read<ReportProvider>();
    searchObject.deviceId = widget.device.id;
    searchObject.includeTotalCount = true;
    searchObject.pageSize = 3;
    isLoading = true;
    initValues();
  }

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }

  Future<void> initValues() async {
    try {
      reportList = await _reportProvider.get(filter: searchObject.toJson());
    } on ApiClientException catch (e) {
      if (!mounted) return;
      alertBoxMoveBack(context, "Error", e.message, onRetry: initValues);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        spacing: 10,
        children: [
          Text(widget.officeName, style: theme.textTheme.displayLarge),
          const SizedBox(height: 100),
          SizedBox(
            width: 500,
            child: Table(
              border: TableBorder.all(color: theme.colorScheme.primary),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {0: IntrinsicColumnWidth()},
              children: [
                _buildRow(context, 'Device name', widget.device.name ?? "-"),
                _buildRow(
                  context,
                  'IP address',
                  widget.device.ipAddress ?? "-",
                ),
                _buildRow(context, 'OS and version', widget.device.os ?? "-"),
                _buildRow(context, 'Last OS update', "-"),
                _buildRow(
                  context,
                  'Reported problems count',
                  isLoading
                      ? '-'
                      : reportList.totalCount != null
                      ? reportList.totalCount.toString()
                      : '-',
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
          Text(
            "Reports which have this device tagged",
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),

          isLoading
              ? globalLoadingSpinner()
              : ReportsChild(size: 0.5, reportList: reportList),
          const SizedBox(height: 50),
          Text(
            "Remote control",
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 600,
            width: 1200,
            child: Row(
              spacing: 50,
              children: [
                Expanded(
                  child: Column(
                    spacing: 10,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomDropDown(
                        label: "Execution mode",
                        items: <int, String>{},
                      ),
                      CustomTextField(
                        labelText: "Commands",
                        controller: _commandController,
                        readOnly: false,
                        maxLines: 20,
                        minLines: 15,
                        textStyle: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w100,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          PrimaryButton(onPressed: () {}, label: "Send"),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CustomTextField(
                    labelText: "Output",
                    readOnly: true,
                    maxLines: 40,
                    minLines: 20,
                    textStyle: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w100,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
