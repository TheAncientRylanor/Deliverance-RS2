import 'package:deliverance_desktop/layouts/master_screen.dart';
import 'package:deliverance_desktop/models/office.dart';
import 'package:deliverance_desktop/providers/office_provider.dart';
import 'package:deliverance_desktop/screens/add_office_screen.dart';
import 'package:deliverance_desktop/utils/api_client_exception.dart';
import 'package:deliverance_desktop/utils/constants.dart';
import 'package:deliverance_desktop/utils/util_widgets.dart';
import 'package:deliverance_desktop/widgets/custom_buttons.dart';
import 'package:deliverance_desktop/widgets/custom_drop_down.dart';
import 'package:deliverance_desktop/widgets/device_details_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class OfficesScreen extends StatefulWidget {
  const OfficesScreen({super.key});

  @override
  State<OfficesScreen> createState() => _OfficesScreenState();
}

class _OfficesScreenState extends State<OfficesScreen> {
  late OfficeProvider _officeProvider;
  Map<int, String> _offices = {};
  late Office _selectedOffice;
  int? selectedKey;
  bool isLoading = true;
  bool isLoadingOffice = false;
  @override
  void initState() {
    super.initState();
    isLoading = true;
    initValues();
  }

  void initValues() async {
    _officeProvider = context.read<OfficeProvider>();
    loadValues();
  }

  void loadValues() async {
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

  Future<void> _getOffice() async {
    isLoadingOffice = true;
    try {
      if (selectedKey != null) {
        _selectedOffice = await _officeProvider.getById(selectedKey!);
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
    return MasterScreen(
      title: "Offices",
      child: isLoading
          ? globalLoadingSpinner()
          : FractionallySizedBox(
              widthFactor: 0.9,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 100),
                    Wrap(
                      spacing: 50,
                      runSpacing: 20,
                      alignment: WrapAlignment.end,
                      runAlignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        CustomDropDown(
                          items: _offices,
                          label: "Offices",
                          onChanged: (value) => {
                            setState(() {
                              selectedKey = value;
                            }),
                            _getOffice(),
                          },
                        ),
                        SecondaryButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddOfficeScreen(),
                              ),
                            );
                            if (!mounted) return;
                            if (result == true) {
                              setState(() {
                                isLoading = true;
                              });
                              loadValues();
                            }
                          },
                          label: "Add new office",
                          icon: Icon(Icons.add, size: 25),
                          width: 205,
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 50),
                      child: Stack(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final height = (constraints.maxWidth * 0.5).clamp(
                                400.0,
                                700.0,
                              );
                              final Size canvasSize = Size(
                                constraints.maxWidth,
                                height,
                              );
                              return Container(
                                width: double.infinity,
                                height: height,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainer,
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: isLoadingOffice
                                    ? globalLoadingSpinner()
                                    : selectedKey != null
                                    ? _drawOffice(canvasSize)
                                    : null,
                              );
                            },
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Icon(
                              Icons.fullscreen,
                              color: Theme.of(context).colorScheme.primary,
                              size: 80,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        PrimaryButton(
                          onPressed: selectedKey == null
                              ? null
                              : () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddOfficeScreen(
                                        office: _selectedOffice,
                                      ),
                                    ),
                                  );
                                  if (!mounted) return;
                                  if (result == true) {
                                    setState(() {
                                      isLoading = true;
                                    });
                                    loadValues();
                                    _getOffice();
                                  }
                                },
                          label: "Edit",
                          icon: Icon(
                            Icons.edit,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 50),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _drawOffice(Size canvasSize) {
    return Stack(
      children: [
        for (var device in _selectedOffice.devices ?? [])
          Positioned(
            left: device.positionX * canvasSize.width,
            top: device.positionY * canvasSize.height,
            child: Column(
              children: [
                IconButton(
                  mouseCursor: SystemMouseCursors.click,
                  onPressed: () {
                    showDeviceDetailsDialog(context, device);
                  },
                  icon: SvgPicture.asset(
                    iconForType((device.type as String)),
                    width: 80.0,
                    height: 80.0,
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
