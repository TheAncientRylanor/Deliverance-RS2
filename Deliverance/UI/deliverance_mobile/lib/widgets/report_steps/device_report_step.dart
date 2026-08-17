import 'package:deliverance_mobile/models/office.dart';
import 'package:deliverance_mobile/models/report.dart';
import 'package:deliverance_mobile/widgets/custom_buttons.dart';
import 'package:deliverance_mobile/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

class DeviceReportStep extends StatefulWidget {
  final Devices _selectedDevice;
  const DeviceReportStep({super.key, required this._selectedDevice});

  static Future<DeviceReport?> show(BuildContext context, Devices device) {
    return showDialog<DeviceReport>(
      context: context,
      builder: (context) => DeviceReportStep(selectedDevice: device),
    );
  }

  @override
  _DeviceReportStepState createState() => _DeviceReportStepState();
}

class _DeviceReportStepState extends State<DeviceReportStep> {
  TextEditingController _description = TextEditingController();
  String _selectedOccurance = "";
  late DeviceReport deviceReport;
  @override
  Widget build(BuildContext context) {
    TextStyle? style = Theme.of(context).textTheme.labelMedium;
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            spacing: 20,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildContent(context, style),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TextStyle? style) {
    return Column(
      spacing: 20,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget._selectedDevice.officeName as String,
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
                      'Manufacturer',
                      style: style?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Reported before',
                      style: style?.copyWith(fontWeight: FontWeight.bold),
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
                      widget._selectedDevice.name as String,
                      style: style,
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
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('YES', style: style),
                  ),
                ),
              ],
            ),
          ],
        ),
        CustomTextField(textStyle: Theme.of(context).textTheme.headlineLarge),
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
                            onChanged: (value) {
                              setState(() {
                                _selectedOccurance = value ?? '';
                              });
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                RadioListTile<String>(
                                  title: Text("Yes"),
                                  value: "Yes",
                                ),
                                RadioListTile<String>(
                                  title: Text("No"),
                                  value: "No",
                                ),
                                RadioListTile<String>(
                                  title: Text("Not sure"),
                                  value: "Not sure",
                                ),
                              ],
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
          children: [
            SecondaryButton(
              onPressed: () {
                Navigator.pop(context);
              },
              label: "Cancel",
            ),
            PrimaryButton(
              onPressed: () {
                deviceReport = DeviceReport(
                  detail: _description.text,
                  deviceId: widget._selectedDevice.id,
                  occurance: _selectedOccurance,
                );
                Navigator.pop(context, deviceReport);
              },
              label: "Report",
            ),
          ],
        ),
      ],
    );
  }
}
