import 'package:deliverance_mobile/models/issue_enum.dart';
import 'package:deliverance_mobile/models/report.dart';
import 'package:deliverance_mobile/widgets/custom_buttons.dart';
import 'package:deliverance_mobile/widgets/custom_text_field.dart';
import 'package:deliverance_mobile/widgets/report_summary.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportDetailsScreen extends StatefulWidget {
  final Report report;
  const ReportDetailsScreen({super.key, required this.report});

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  static final _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  late final TextEditingController _locationController;
  late final TextEditingController _devicesController;
  late final TextEditingController _dateController;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _commentController;
  late final TextEditingController _dateClearedController;
  late final TextEditingController _clearedByController;

  bool get _isCleared => widget.report.status == "ClearedReportState";
  bool get _hasComment => widget.report.comment?.isNotEmpty ?? false;

  @override
  void initState() {
    super.initState();
    final report = widget.report;
    final officeReports = report.officeReports ?? [];
    final dateCleared = report.dateCleared;

    _locationController = TextEditingController(
      text: officeReports.map((x) => x.name).join("; "),
    );
    _devicesController = TextEditingController(
      text: officeReports
          .map(
            (o) =>
                "${o.name} - ${o.deviceReports.map((x) => x.name).join(",")}",
          )
          .join(";\n"),
    );
    _dateController = TextEditingController(
      text: _dateFormat.format(report.dateReported),
    );
    _titleController = TextEditingController(text: report.reportName ?? "");
    _descriptionController = TextEditingController(text: report.detail ?? "");
    _commentController = TextEditingController(text: report.comment ?? "");
    _dateClearedController = TextEditingController(
      text: dateCleared == null ? '-' : _dateFormat.format(dateCleared),
    );
    _clearedByController = TextEditingController(
      text: report.reportClearedBy ?? '-',
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    _devicesController.dispose();
    _dateController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _commentController.dispose();
    _dateClearedController.dispose();
    _clearedByController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final issueType = report.issueType;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              spacing: 40,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Report details",
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                ReportSummary(
                  locationController: _locationController,
                  devicesController: _devicesController,
                  dateController: _dateController,
                  selectedOccurrence: report.reportOccurrences ?? [],
                  titleController: _titleController,
                  descriptionController: _descriptionController,
                  severity: report.severity?.toDouble(),
                  issueType: issueType == null
                      ? null
                      : IssueEnum.fromValue(issueType),
                ),
                if (_isCleared) _buildClearedSection(context),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SecondaryButton(
                    label: 'Back',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClearedSection(BuildContext context) {
    final style = Theme.of(context).textTheme.titleSmall;

    return Column(
      spacing: 40,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "1.4 Resolution",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (_hasComment)
          CustomTextField(
            labelText: "Admin comment",
            textStyle: style,
            readOnly: true,
            minLines: 4,
            maxLines: 20,
            controller: _commentController,
          ),
        CustomTextField(
          labelText: "Date cleared",
          textStyle: style,
          readOnly: true,
          controller: _dateClearedController,
        ),
        CustomTextField(
          labelText: "Cleared by",
          textStyle: style,
          readOnly: true,
          controller: _clearedByController,
        ),
      ],
    );
  }
}
