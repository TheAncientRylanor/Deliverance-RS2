import 'package:deliverance_mobile/models/answer_enum.dart';
import 'package:deliverance_mobile/models/office.dart';
import 'package:deliverance_mobile/models/report.dart';
import 'package:deliverance_mobile/widgets/custom_buttons.dart';
import 'package:deliverance_mobile/widgets/custom_text_field.dart';
import 'package:deliverance_mobile/utils/form_validators.dart';
import 'package:flutter/material.dart';

class DeviceReportStep extends StatefulWidget {
  final Devices _selectedDevice;
  final String _officeName;
  final DeviceReport? _deviceReport;
  const DeviceReportStep({
    super.key,
    required this._selectedDevice,
    required this._officeName,
    required this._deviceReport,
  });

  static Future<DeviceReport?> show(
    BuildContext context,
    Devices device,
    String officeName,
    DeviceReport? deviceReport,
  ) {
    return showDialog<DeviceReport>(
      context: context,
      builder: (context) => DeviceReportStep(
        selectedDevice: device,
        officeName: officeName,
        deviceReport: deviceReport,
      ),
    );
  }

  @override
  State<DeviceReportStep> createState() => _DeviceReportStepState();
}

class _DeviceReportStepState extends State<DeviceReportStep> {
  final TextEditingController _description = TextEditingController();
  String _selectedOccurrence = "";
  late DeviceReport deviceReport;

  @override
  void initState() {
    super.initState();
    _description.text = widget._deviceReport?.detail ?? "";
    _selectedOccurrence = widget._deviceReport?.occurrence ?? "";
  }

  String get _reportedBefore {
    final times = widget._selectedDevice.timesReported;
    if (times == null) return "Unknown";
    if (times == 0) return "No";
    final count = times == 1 ? "Yes, once" : "Yes, $times times";
    return widget._selectedDevice.hasOpenReport == true
        ? "$count, one still open"
        : count;
  }

  @override
  Widget build(BuildContext context) {
    TextStyle? style = Theme.of(context).textTheme.labelMedium;
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            spacing: 20,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [_buildContent(context, style)],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TextStyle? style) {
    return Column(
      spacing: 40,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget._officeName,
          style: Theme.of(context).textTheme.displayLarge,
        ),
        Table(
          border: TableBorder.all(color: Theme.of(context).colorScheme.primary),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: <TableRow>[
            TableRow(
              children: [
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Device name',
                      style: style?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      widget._selectedDevice.name as String,
                      style: style,
                    ),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Manufacturer',
                      style: style?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      widget._selectedDevice.manufacturer ?? "Unknown",
                      style: style,
                    ),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Reported before',
                      style: style?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(_reportedBefore, style: style),
                  ),
                ),
              ],
            ),
          ],
        ),
        CustomTextField(
          textStyle: Theme.of(context).textTheme.titleSmall,
          minLines: 4,
          maxLines: 30,
          labelText: "1. Description",
          controller: _description,
          maxLength: FieldLimits.deviceDetailMax,
          validator: maxLength('Description', FieldLimits.deviceDetailMax),
        ),
        Column(
          children: [
            Container(
              height: 250,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "2.1 Have you ever encountered this problem previously?",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 10),
                        RadioGroup<String>(
                          groupValue: _selectedOccurrence.isEmpty
                              ? null
                              : _selectedOccurrence,
                          onChanged: (value) {
                            setState(() {
                              _selectedOccurrence = value ?? '';
                            });
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: AnswerEnum.values
                                .map(
                                  (answer) => RadioListTile<String>(
                                    title: Text(answer.label),
                                    value: answer.label,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: SecondaryButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                label: "Cancel",
              ),
            ),
            Expanded(
              child: PrimaryButton(
                onPressed: () {
                  deviceReport = DeviceReport(
                    id: widget._deviceReport?.id,
                    detail: _description.text,
                    deviceId: widget._selectedDevice.id,
                    occurrence: _selectedOccurrence,
                    officeReportId: widget._deviceReport?.officeReportId,
                    name: widget._selectedDevice.name,
                  );
                  Navigator.pop(context, deviceReport);
                },
                label: "Report",
              ),
            ),
          ],
        ),
      ],
    );
  }
}
