import 'package:deliverance_desktop/layouts/master_screen.dart';
import 'package:deliverance_desktop/models/office.dart';
import 'package:deliverance_desktop/providers/office_provider.dart';
import 'package:deliverance_desktop/screens/add_office_screen.dart';
import 'package:deliverance_desktop/utils/api_client_exception.dart';
import 'package:deliverance_desktop/utils/util_widgets.dart';
import 'package:deliverance_desktop/widgets/custom_buttons.dart';
import 'package:deliverance_desktop/widgets/custom_drop_down.dart';
import 'package:deliverance_desktop/widgets/office_canvas.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OfficesScreen extends StatefulWidget {
  const OfficesScreen({super.key});

  @override
  State<OfficesScreen> createState() => _OfficesScreenState();
}

class _OfficesScreenState extends State<OfficesScreen> {
  late OfficeProvider _officeProvider;
  Map<int, String> _offices = {};
  Office? _selectedOffice;
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
      final offices = await _officeProvider.getAll();
      _offices = Map.fromEntries(
        offices.map(
          (office) => MapEntry(office.id as int, office.name as String),
        ),
      );
    } on ApiClientException catch (e) {
      if (!mounted) return;
      alertBoxMoveBack(context, "Error", e.message, onRetry: loadValues);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _getOffice() async {
    setState(() {
      isLoadingOffice = true;
      // Drop the previous office so a failed load can't leave it on screen
      // under a different selection.
      _selectedOffice = null;
    });
    try {
      if (selectedKey != null) {
        _selectedOffice = await _officeProvider.getById(selectedKey!);
      }
    } on ApiClientException catch (e) {
      if (!mounted) return;
      alertBox(context, "Error", e.message);
    } finally {
      if (mounted) {
        setState(() {
          isLoadingOffice = false;
        });
      }
    }
  }

  Future<void> _enterFullScreenMap() async {
    final office = _selectedOffice;
    if (office == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullScreenOfficeMap(
          office: office,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          iconColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
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
                    const SizedBox(height: 100),
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
                          onChanged: (value) {
                            selectedKey = value;
                            _getOffice();
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
                                    : _selectedOffice != null
                                    ? OfficeCanvas(
                                        office: _selectedOffice!,
                                        canvasSize: canvasSize,
                                        isReport: false,
                                      )
                                    : null,
                              );
                            },
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: IconButton(
                              onPressed: _selectedOffice == null
                                  ? null
                                  : _enterFullScreenMap,
                              icon: Icon(Icons.fullscreen, size: 80),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        PrimaryButton(
                          onPressed: _selectedOffice == null
                              ? null
                              : () async {
                                  final office = _selectedOffice!;
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AddOfficeScreen(office: office),
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
}

class _FullScreenOfficeMap extends StatelessWidget {
  final Office office;
  final Color backgroundColor;
  final Color iconColor;

  const _FullScreenOfficeMap({
    required this.office,
    required this.backgroundColor,
    required this.iconColor,
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
                Positioned.fill(
                  child: OfficeCanvas(
                    office: office,
                    canvasSize: canvasSize,
                    isReport: false,
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.fullscreen_exit,
                      color: iconColor,
                      size: 80,
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
