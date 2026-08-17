import 'package:deliverance_mobile/models/office.dart';
import 'package:deliverance_mobile/models/report.dart';
import 'package:deliverance_mobile/providers/office_provider.dart';
import 'package:deliverance_mobile/utils/api_client_exception.dart';
import 'package:deliverance_mobile/utils/constants.dart';
import 'package:deliverance_mobile/utils/util_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../custom_buttons.dart';
import '../custom_drop_down.dart';
import 'device_report_step.dart';

class LocationStep extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final TextEditingController locationController;
  final TextEditingController devicesController;
  final List<OfficeReport> officeReports;
  const LocationStep({
    super.key,
    this.onBack,
    this.onNext,
    required this.locationController,
    required this.devicesController,
    required this.officeReports,
  });

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  int? selectedLocation;
  bool isChecked = false;
  List<Office> _selectedOffice = [];

  late OfficeProvider _officeProvider;
  Map<int, String> _offices = {};
  bool isLoading = true;
  bool isLoadingOffice = false;
  int currentOfficeIndex = 0;
  @override
  void initState() {
    super.initState();
    _officeProvider = context.read<OfficeProvider>();
    initValues();
  }

  Future<void> initValues() async {
    try {
      var result = await _officeProvider.get();
      if (result.items != null && result.items!.isNotEmpty) {
        _offices = Map.fromEntries(
          result.items!.map(
            (office) => MapEntry(office.id as int, office.name as String),
          ),
        );
      }
    } on ApiClientException catch (e) {
      alertBox(context, "Error", e.message);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getOffice() async {
    isLoadingOffice = true;
    try {
      if (selectedLocation != null) {
        var office = await _officeProvider.getById(selectedLocation!);
        _selectedOffice.add(office);
        widget.officeReports.add(OfficeReport(officeId: office.id));
      }
    } on ApiClientException catch (e) {
      alertBox(context, "Error", e.message);
    } finally {
      setState(() {
        isLoadingOffice = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          spacing: 40,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomDropDown(
              mode: DropDownMode.multi,
              label: '1. Location',
              textStyle: Theme.of(context).textTheme.titleSmall,
              items: _offices,
              initialValue: selectedLocation,
              onChangedMulti: (values) {
                widget.locationController.text = values.join('; ');
              },
            ),
            const SizedBox(height: 50),
            Text(
              "2. Device affected",
              style: Theme.of(context).textTheme.titleSmall,
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final height = (constraints.maxWidth * 0.5).clamp(350.0, 500.0);
                final Size canvasSize = Size(constraints.maxWidth, height);
                return Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  child: isLoadingOffice
                      ? globalLoadingSpinner()
                      : selectedLocation != null
                      ? _drawOffice(canvasSize)
                      : null,
                );
              },
            ),
            Text(
              "Select the device on the map which is affected by the problem",
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Row(
              children: [
                Checkbox(
                  value: isChecked,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onChanged: (bool? newValue) {
                    setState(() {
                      isChecked = newValue ?? false;
                      widget.devicesController.text = isChecked
                          ? 'No specific affected device'
                          : '';
                    });
                  },
                ),
                Text(
                  "This location does not have a specific affected device",
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight(200)),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RotatedBox(
                  quarterTurns: 2,
                  child: IconButton(
                    icon: Icon(Icons.arrow_forward_ios),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () {},
                    iconSize: 40,
                  ),
                ),
                SizedBox(width: 20),
                Text("1 of 1", style: Theme.of(context).textTheme.labelMedium),
                SizedBox(width: 20),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: () {},
                  iconSize: 40,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SecondaryButton(label: 'Back', onPressed: widget.onBack),
                PrimaryButton(label: 'Next', onPressed: widget.onNext),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawOffice(Size canvasSize) {
    return Stack(
      children: [
        for (var device in _selectedOffice[currentOfficeIndex].devices ?? [])
          Positioned(
            left: device.positionX * canvasSize.width,
            top: device.positionY * canvasSize.height,
            child: Column(
              children: [
                IconButton(
                  mouseCursor: SystemMouseCursors.click,
                  onPressed: () async {
                    final result = await DeviceReportStep.show(context, device);
                    if (result != null) {
                      setState(() {
                        widget.officeReports[currentOfficeIndex].deviceReports
                            ?.removeWhere((r) => r.deviceId == result.deviceId);
                        widget.officeReports[currentOfficeIndex].deviceReports
                            ?.add(result);
                      });
                    }
                  },
                  icon: SvgPicture.asset(
                    iconForType((device.type as String)),
                    width: 40.0,
                    height: 40.0,
                    colorFilter: ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                Text(
                  device.name ?? "",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
