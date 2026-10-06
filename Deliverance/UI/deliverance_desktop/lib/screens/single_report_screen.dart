import 'package:deliverance_desktop/models/issue_enum.dart';
import 'package:deliverance_desktop/models/office.dart';
import 'package:deliverance_desktop/models/report.dart';
import 'package:deliverance_desktop/models/report_state_enum.dart';
import 'package:deliverance_desktop/models/severity_enum.dart';
import 'package:deliverance_desktop/providers/office_provider.dart';
import 'package:deliverance_desktop/providers/report_provider.dart';
import 'package:deliverance_desktop/utils/api_client_exception.dart';
import 'package:deliverance_desktop/utils/util_widgets.dart';
import 'package:deliverance_desktop/widgets/custom_buttons.dart';
import 'package:deliverance_desktop/widgets/custom_drop_down.dart';
import 'package:deliverance_desktop/widgets/custom_text_field.dart';
import 'package:deliverance_desktop/widgets/occurance_dialog.dart';
import 'package:deliverance_desktop/widgets/office_canvas.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SingleReportScreen extends StatefulWidget {
  final Report report;

  const SingleReportScreen({super.key, required this.report});

  @override
  State<SingleReportScreen> createState() => _SingleReportScreenState();
}

class _SingleReportScreenState extends State<SingleReportScreen> {
  late final TextEditingController _detailController;
  final TextEditingController _commentController = TextEditingController();
  late OfficeProvider _officeProvider;
  late ReportProvider _reportProvider;
  Map<OfficeReport, String> _offices = {};
  Office? _selectedOffice;
  OfficeReport? selectedReport;
  bool isLoadingOffice = false;
  @override
  void initState() {
    super.initState();
    _detailController = TextEditingController(text: widget.report.detail ?? '');
    _officeProvider = context.read<OfficeProvider>();
    _reportProvider = context.read<ReportProvider>();
    _offices = Map.fromEntries(
      (widget.report.officeReports ?? []).map(
        (officeReport) => MapEntry(officeReport, officeReport.name ?? ''),
      ),
    );
    if (widget.report.status == ReportStateEnum.unseen.label) seeReport();
  }

  Future<void> seeReport() async {
    if (widget.report.status != ReportStateEnum.seen.label) {
      try {
        await _reportProvider.seen(widget.report.id!);
      } on ApiClientException catch (e) {
        if (!mounted) return;
        alertBox(context, "Error", e.message);
      }
    }
  }

  Future<void> _getOffice() async {
    setState(() {
      isLoadingOffice = true;
    });
    try {
      if (selectedReport != null) {
        _selectedOffice = await _officeProvider.getFromReport(
          selectedReport!.id,
          selectedReport!.officeId,
        );
      }
    } on ApiClientException catch (e) {
      if (mounted) alertBox(context, "Error", e.message);
    } finally {
      if (mounted) {
        setState(() {
          isLoadingOffice = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _detailController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String get _formattedDate {
    final date = widget.report.dateReported;
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String get _severityLabel {
    final severity = widget.report.severity;
    if (severity == null) return '-';
    return SeverityEnum.fromValue(severity).label;
  }

  String get _issueTypeLabel {
    final issueType = widget.report.issueType;
    if (issueType == null) return '-';
    return IssueEnum.fromValue(issueType).label;
  }

  String get _locationLabel {
    final officeNames = widget.report.officeReports
        ?.map((officeReport) => officeReport.name)
        .whereType<String>()
        .toList();
    if (officeNames == null || officeNames.isEmpty) return '-';
    return officeNames.join(', ');
  }

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 30,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              widget.report.reportName ?? "",
              style: theme.textTheme.displayLarge,
              textAlign: TextAlign.center,
            ),
          ),
          Table(
            border: TableBorder.all(color: theme.colorScheme.primary),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {0: IntrinsicColumnWidth()},
            children: [
              _buildRow(
                context,
                'Report from',
                widget.report.user?.username ?? '-',
              ),
              _buildRow(context, 'Date sent', _formattedDate),
              _buildRow(context, 'Location', _locationLabel),
              _buildRow(
                context,
                'Occurance',
                "-",
                button: PrimaryButton(
                  onPressed: () => showOccuranceDialog(
                    context,
                    widget.report.reportOccurances ?? [],
                  ),
                  label: "Occurance",
                  width: 100,
                  height: 40,
                ),
              ),
              _buildRow(context, 'Severity', _severityLabel),
              _buildRow(context, 'Issue type', _issueTypeLabel),
            ],
          ),
          Text("Description:", style: theme.textTheme.headlineMedium),
          CustomTextField(
            controller: _detailController,
            readOnly: true,
            maxLines: 30,
            minLines: 10,
            textStyle: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w100,
            ),
          ),
          const SizedBox(height: 20),
          Text("Devices affected:", style: theme.textTheme.headlineMedium),
          CustomDropDown(
            items: _offices,
            label: "Offices",
            onChanged: (value) => {
              setState(() {
                selectedReport = value;
              }),
              _getOffice(),
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final height = (constraints.maxWidth * 0.5).clamp(
                      400.0,
                      700.0,
                    );
                    final Size canvasSize = Size(constraints.maxWidth, height);
                    return Container(
                      width: double.infinity,
                      height: height,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        border: Border.all(color: theme.colorScheme.primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: isLoadingOffice
                          ? globalLoadingSpinner()
                          : selectedReport != null && _selectedOffice != null
                          ? OfficeCanvas(
                              office: _selectedOffice!,
                              canvasSize: canvasSize,
                              isReport: true,
                            )
                          : null,
                    );
                  },
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Icon(
                    Icons.fullscreen,
                    color: theme.colorScheme.primary,
                    size: 80,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (widget.report.status == ReportStateEnum.cleared.label) ...[
            Text("Add comment:", style: theme.textTheme.headlineMedium),
            CustomTextField(
              controller: _commentController,
              readOnly: false,
              maxLines: 30,
              minLines: 10,
              textStyle: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w100,
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (widget.report.status == ReportStateEnum.cleared.label)
            Row(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SecondaryButton(onPressed: () {}, label: "False alarm"),
                PrimaryButton(onPressed: () {}, label: "Issue cleared"),
              ],
            ),
        ],
      ),
    );
  }
}
