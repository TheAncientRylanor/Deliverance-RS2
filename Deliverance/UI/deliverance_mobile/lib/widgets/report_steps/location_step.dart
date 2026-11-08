import 'package:deliverance_mobile/models/office.dart';
import 'package:deliverance_mobile/models/report.dart';
import 'package:deliverance_mobile/providers/office_provider.dart';
import 'package:deliverance_mobile/utils/api_client_exception.dart';
import 'package:deliverance_mobile/utils/constants.dart';
import 'package:deliverance_mobile/utils/util_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final GlobalKey<FormState> locationKey;
  const LocationStep({
    super.key,
    required this.locationKey,
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
  bool isChecked = false;
  final List<Office> _selectedOffice = [];
  List<int> _selectedOfficeIds = [];

  late OfficeProvider _officeProvider;
  Map<int, String> _offices = {};
  bool isLoading = true;
  bool isLoadingOffice = false;
  int currentOfficeIndex = 0;
  @override
  void initState() {
    super.initState();
    _officeProvider = context.read<OfficeProvider>();
    _selectedOfficeIds = widget.officeReports
        .map((report) => report.officeId)
        .whereType<int>()
        .toList();
    initValues();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _enterFullScreenMap() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullScreenDeviceMap(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          iconColor: Theme.of(context).colorScheme.primary,
          drawOffice: _drawOffice,
          hasOffice: _selectedOffice.isNotEmpty,
        ),
      ),
    );
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  Future<void> initValues() async {
    try {
      final allOffices = _officeProvider.get();
      final selected = _fetchOfficesByIds(_selectedOfficeIds);
      await Future.wait([allOffices, selected]);
      final result = await allOffices;
      final selectedOffices = await selected;
      if (result.items != null && result.items!.isNotEmpty) {
        _offices = {
          for (final office in result.items!)
            if (office.id != null) office.id!: office.name ?? '',
        };
      }
      _selectedOffice.addAll(selectedOffices);
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    } on ApiClientException catch (e) {
      if (!mounted) return;
      alertBoxMoveBack(context, "Error", e.message, onRetry: initValues);
    }
  }

  List<String> _validationErrors() {
    final errors = <String>[];
    if (_selectedOfficeIds.isEmpty) {
      errors.add("Select at least one office where the problem happened");
    }
    return errors;
  }

  String? _locationError;

  void _handleNext() {
    final isFormValid = widget.locationKey.currentState?.validate() ?? true;
    final errors = _validationErrors();
    setState(() => _locationError = errors.isEmpty ? null : errors.first);
    if (isFormValid && errors.isEmpty) {
      widget.onNext?.call();
    }
  }

  Future<List<Office>> _fetchOfficesByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final result = await _officeProvider.get(
      filter: {'Offices': ids, 'PageSize': ids.length},
    );
    return result.items ?? [];
  }

  Future<void> onOfficeSelectionChanged(List<int> newIds) async {
    final addedIds = newIds
        .where((id) => !_selectedOfficeIds.contains(id))
        .toList();
    final removedIds = _selectedOfficeIds
        .where((id) => !newIds.contains(id))
        .toList();

    if (removedIds.isNotEmpty) {
      setState(() {
        final currentOfficeId = currentOfficeIndex < _selectedOffice.length
            ? _selectedOffice[currentOfficeIndex].id
            : null;
        _selectedOffice.removeWhere((office) => removedIds.contains(office.id));
        widget.officeReports.removeWhere(
          (report) => removedIds.contains(report.officeId),
        );
        if (_selectedOffice.isEmpty) {
          currentOfficeIndex = 0;
        } else {
          final newIndex = currentOfficeId == null
              ? -1
              : _selectedOffice.indexWhere(
                  (office) => office.id == currentOfficeId,
                );
          currentOfficeIndex = newIndex != -1
              ? newIndex
              : currentOfficeIndex.clamp(0, _selectedOffice.length - 1);
        }
      });
    }

    _selectedOfficeIds = newIds;

    if (addedIds.isEmpty) {
      return;
    }

    await _loadAddedOffices(addedIds);
  }

  Future<void> _loadAddedOffices(List<int> addedIds) async {
    setState(() {
      isLoadingOffice = true;
    });
    try {
      final offices = await _fetchOfficesByIds(addedIds);
      for (var office in offices) {
        _selectedOffice.add(office);
        final alreadyHasReport = widget.officeReports.any(
          (report) => report.officeId == office.id,
        );
        if (!alreadyHasReport) {
          widget.officeReports.add(
            OfficeReport(officeId: office.id, name: office.name),
          );
        }
      }
    } on ApiClientException catch (e) {
      if (!mounted) return;
      alertBoxMoveBack(
        context,
        "Error",
        e.message,
        onRetry: () => _loadAddedOffices(addedIds),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoadingOffice = false;
        });
      }
    }
  }

  OfficeReport? _currentOfficeReport() {
    if (currentOfficeIndex >= _selectedOffice.length) return null;
    final officeId = _selectedOffice[currentOfficeIndex].id;
    for (final report in widget.officeReports) {
      if (report.officeId == officeId) {
        return report;
      }
    }
    return null;
  }

  DeviceReport? _findDeviceReport(int deviceId) {
    final officeReport = _currentOfficeReport();
    if (officeReport == null) return null;
    for (final report in officeReport.deviceReports) {
      if (report.deviceId == deviceId) {
        return report;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: isLoading
          ? globalLoadingSpinner()
          : Form(
              key: widget.locationKey,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                child: Column(
                  spacing: 40,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomDropDown<int>(
                      mode: DropDownMode.multi,
                      label: '1. Location',
                      textStyle: Theme.of(context).textTheme.titleSmall,
                      items: _offices,
                      initialValues: _selectedOfficeIds,
                      onBeforeRemove: (context, officeId) async {
                        final officeName =
                            _offices[officeId] ?? 'this location';
                        final confirmed = await alertBox(
                          context,
                          'Remove location',
                          'Are you sure you want to remove $officeName? '
                              'All reports for this location will be deleted.',
                        );
                        return confirmed ?? false;
                      },
                      onChangedMulti: (values) {
                        widget.locationController.text = values
                            .map((id) => _offices[id] ?? '')
                            .join('; ');
                        if (values.isNotEmpty && _locationError != null) {
                          setState(() => _locationError = null);
                        }
                        onOfficeSelectionChanged(values);
                      },
                    ),
                    if (_locationError != null)
                      Text(
                        _locationError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    Text(
                      "2. Device affected",
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final height = (constraints.maxWidth * 0.5).clamp(
                          350.0,
                          500.0,
                        );
                        final Size canvasSize = Size(
                          constraints.maxWidth,
                          height,
                        );
                        return Stack(
                          children: [
                            Container(
                              height: height,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              child: isLoadingOffice
                                  ? globalLoadingSpinner()
                                  : _selectedOffice.isNotEmpty
                                  ? _drawOffice(canvasSize)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: IconButton(
                                onPressed: _enterFullScreenMap,
                                icon: Icon(
                                  Icons.fullscreen,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 40,
                                ),
                              ),
                            ),
                          ],
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
                        Expanded(
                          child: Text(
                            "This location does not have a specific affected device",
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(fontWeight: FontWeight(200)),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedOffice.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RotatedBox(
                            quarterTurns: 2,
                            child: IconButton(
                              icon: Icon(Icons.arrow_forward_ios),
                              color: currentOfficeIndex == 0
                                  ? Colors.grey
                                  : Theme.of(context).colorScheme.primary,
                              onPressed: () {
                                if (currentOfficeIndex != 0) {
                                  setState(() {
                                    currentOfficeIndex--;
                                  });
                                }
                              },
                              iconSize: 40,
                            ),
                          ),
                          SizedBox(width: 20),
                          Text(
                            "${currentOfficeIndex + 1} of ${_selectedOffice.length}",
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          SizedBox(width: 20),
                          IconButton(
                            icon: Icon(Icons.arrow_forward_ios),
                            color:
                                currentOfficeIndex == _selectedOffice.length - 1
                                ? Colors.grey
                                : Theme.of(context).colorScheme.primary,
                            onPressed: () {
                              if (currentOfficeIndex <
                                  _selectedOffice.length - 1) {
                                setState(() {
                                  currentOfficeIndex++;
                                });
                              }
                            },
                            iconSize: 40,
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SecondaryButton(
                          label: 'Back',
                          onPressed: widget.onBack,
                        ),
                        PrimaryButton(label: 'Next', onPressed: _handleNext),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _drawOffice(Size canvasSize) {
    return Stack(
      children: [
        for (final Devices device
            in _selectedOffice[currentOfficeIndex].devices ?? <Devices>[])
          Positioned(
            left: (device.positionX ?? 0) * canvasSize.width,
            top: (device.positionY ?? 0) * canvasSize.height,
            child: Column(
              children: [
                IconButton(
                  mouseCursor: SystemMouseCursors.click,
                  onPressed: () async {
                    final result = await DeviceReportStep.show(
                      context,
                      device,
                      _selectedOffice[currentOfficeIndex].name ?? '',
                      device.id == null ? null : _findDeviceReport(device.id!),
                    );
                    if (result != null) {
                      setState(() {
                        final officeReport = _currentOfficeReport();
                        officeReport?.deviceReports.removeWhere(
                          (r) => r.deviceId == result.deviceId,
                        );
                        officeReport?.deviceReports.add(result);
                      });
                    }
                  },
                  icon: SvgPicture.asset(
                    iconForType(device.type ?? ''),
                    width: 40.0,
                    height: 40.0,
                    colorFilter: ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    device.name ?? "",
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FullScreenDeviceMap extends StatelessWidget {
  final Color backgroundColor;
  final Color iconColor;
  final Widget Function(Size canvasSize) drawOffice;
  final bool hasOffice;

  const _FullScreenDeviceMap({
    required this.backgroundColor,
    required this.iconColor,
    required this.drawOffice,
    required this.hasOffice,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final canvasSize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            return Stack(
              children: [
                if (hasOffice) Positioned.fill(child: drawOffice(canvasSize)),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.fullscreen_exit,
                      color: iconColor,
                      size: 40,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
