import 'package:deliverance_desktop/models/office.dart';
import 'package:deliverance_desktop/providers/office_provider.dart';
import 'package:deliverance_desktop/utils/api_client_exception.dart';
import 'package:deliverance_desktop/utils/constants.dart';
import 'package:deliverance_desktop/utils/util_widgets.dart';
import 'package:deliverance_desktop/widgets/custom_buttons.dart';
import 'package:deliverance_desktop/widgets/custom_text_field.dart';
import 'package:deliverance_desktop/widgets/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class AddOfficeScreen extends StatefulWidget {
  final Office? office;

  const AddOfficeScreen({super.key, this.office});

  @override
  State<AddOfficeScreen> createState() => _AddOfficeScreenState();
}

class _PlacedDevice {
  final int? id;
  final String type;
  Offset offset;
  String? deviceName;
  String? ipAddress;
  String? subnetMask;
  String? vlanID;
  String? osAndVersion;
  String? manufacturer;
  String? macAdress;
  _PlacedDevice({
    this.id,
    required this.type,
    required this.offset,
    this.deviceName,
    this.ipAddress,
    this.subnetMask,
    this.vlanID,
    this.osAndVersion,
    this.manufacturer,
    this.macAdress,
  });
}

/// What the device dialog returns: the edited details, or a request to
/// remove the device from the office.
class _DeviceDialogResult {
  final _PlacedDevice? device;
  final bool delete;
  const _DeviceDialogResult.save(this.device) : delete = false;
  const _DeviceDialogResult.delete() : device = null, delete = true;
}

class _AddOfficeScreenState extends State<AddOfficeScreen> {
  static const double _barSize = 250;
  static const double _horizontalSize = 200;
  static const double _collapsedSize = 80;
  static const Duration _drawerDuration = Duration(milliseconds: 250);
  Map<String, String> iconList = {
    "Computer": 'assets/icons/computer.svg',
    "Laptop": 'assets/icons/laptop.svg',
    "Server": 'assets/icons/server.svg',
    "Switch": 'assets/icons/switch.svg',
    "Router": 'assets/icons/router.svg',
  };
  // Size of a placed device on the canvas: an 80px icon plus the IconButton
  // padding, and room for the name below it.
  static const double _deviceWidth = 96;
  static const double _deviceHeight = 120;
  bool _isSaving = false;
  bool _isVerticalBarOpen = true;
  bool _isHorizontalBarOpen = true;
  String _officeName = "";
  final GlobalKey _canvasKey = GlobalKey();
  final List<_PlacedDevice> _placedDevices = [];

  late OfficeProvider _officeProvider;

  bool get _isEditing => widget.office != null;

  @override
  void initState() {
    super.initState();
    final office = widget.office;
    if (office != null) {
      _officeName = office.name ?? "";
      _placedDevices.addAll(
        (office.devices ?? []).map(
          (device) => _PlacedDevice(
            id: device.id,
            type: device.type ?? "",
            offset: Offset(device.positionX ?? 0, device.positionY ?? 0),
            deviceName: device.name,
            ipAddress: device.ipAddress,
            subnetMask: device.subnetMask,
            vlanID: device.vlanID,
            osAndVersion: device.os,
            manufacturer: device.manufacturer,
            macAdress: device.macAddress,
          ),
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _officeProvider = context.read<OfficeProvider>();
  }

  /// Keeps a device's top-left corner (as a fraction of the canvas) inside
  /// the canvas, so the whole device stays visible.
  Offset _clampToCanvas(Offset fraction, Size canvasSize) {
    final maxX = canvasSize.width > _deviceWidth
        ? (canvasSize.width - _deviceWidth) / canvasSize.width
        : 0.0;
    final maxY = canvasSize.height > _deviceHeight
        ? (canvasSize.height - _deviceHeight) / canvasSize.height
        : 0.0;
    return Offset(fraction.dx.clamp(0.0, maxX), fraction.dy.clamp(0.0, maxY));
  }

  void _handleDrop(String type, Offset globalPosition) {
    final RenderBox box =
        _canvasKey.currentContext!.findRenderObject() as RenderBox;
    // globalPosition is the top-left of the drag preview, which is where the
    // device should land.
    final Offset localOffset = box.globalToLocal(globalPosition);
    final Size canvasSize = box.size;
    final newDevice = _PlacedDevice(
      type: type,
      offset: _clampToCanvas(
        Offset(
          localOffset.dx / canvasSize.width,
          localOffset.dy / canvasSize.height,
        ),
        canvasSize,
      ),
    );
    setState(() {
      _placedDevices.add(newDevice);
    });

    _showAddDeviceDialog(context, newDevice, isNew: true);
  }

  Future<void> _saveData() async {
    if (_isSaving) return;
    final result = await _showOfficeName(context, _officeName);
    if (result == null || !mounted) return;
    setState(() {
      _officeName = result;
      _isSaving = true;
    });

    final office = Office(
      name: _officeName,
      devices: _placedDevices
          .map(
            (device) => Devices(
              id: device.id ?? 0,
              name: device.deviceName,
              officeName: _officeName,
              positionX: device.offset.dx,
              positionY: device.offset.dy,
              iconName: device.type.toLowerCase(),
              type: device.type,
              ipAddress: device.ipAddress,
              macAddress: device.macAdress,
              subnetMask: device.subnetMask,
              vlanID: device.vlanID,
              os: device.osAndVersion,
              manufacturer: device.manufacturer,
            ),
          )
          .toList(),
    );
    final officeJson = office.toJson();
    try {
      if (_isEditing) {
        await _officeProvider.update(widget.office!.id!, officeJson);
      } else {
        officeJson.remove('id');
        (officeJson['devices'] as List<dynamic>?)?.forEach((device) {
          (device as Map<String, dynamic>).remove('id');
        });
        await _officeProvider.insert(officeJson);
      }
      if (!mounted) return;
      showCustomToast(context, "Office saved successfully");
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiClientException catch (e) {
      if (!mounted) return;
      alertBox(
        context,
        _isEditing ? "Update error" : "Insert error",
        e.message,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Column createDraggable(String icon, String name) {
    return Column(
      spacing: 10,
      children: [
        Draggable<String>(
          data: name,
          feedback: Material(
            color: Colors.transparent,
            child: SvgPicture.asset(
              icon,
              width: 80.0,
              height: 80.0,
              colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ),
          childWhenDragging: SvgPicture.asset(
            icon,
            width: 30.0,
            height: 30.0,
            colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          child: SvgPicture.asset(
            icon,
            width: 50.0,
            height: 50.0,
            colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
        Text(name, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedContainer(
            duration: _drawerDuration,
            curve: Curves.easeInOut,
            width: _isVerticalBarOpen ? _barSize : _collapsedSize,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(right: BorderSide(color: primaryColor, width: 2)),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Column(
                    spacing: 20,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isVerticalBarOpen
                              ? Icons.arrow_back_outlined
                              : Icons.arrow_forward,
                        ),
                        color: primaryColor,
                        iconSize: 30,
                        onPressed: () {
                          setState(() {
                            _isVerticalBarOpen = !_isVerticalBarOpen;
                          });
                        },
                      ),
                      if (_isVerticalBarOpen) ...[
                        CustomTextField(labelText: "Search device"),
                        SizedBox(height: 50),
                        for (int i = 0; i < iconList.length; i++)
                          createDraggable(
                            iconList.values.elementAt(i),
                            iconList.keys.elementAt(i),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: DragTarget<String>(
                    onAcceptWithDetails: (details) {
                      _handleDrop(details.data, details.offset);
                    },
                    builder: (context, candidateData, rejectedData) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final Size canvasSize = constraints.biggest;
                          return Container(
                            key: _canvasKey,
                            width: double.infinity,
                            height: double.infinity,
                            color: Colors.transparent,
                            child: Stack(
                              children: [
                                for (final device in _placedDevices)
                                  Positioned(
                                    left: device.offset.dx * canvasSize.width,
                                    top: device.offset.dy * canvasSize.height,
                                    child: MouseRegion(
                                      child: GestureDetector(
                                        onPanUpdate: (details) {
                                          setState(() {
                                            device.offset = _clampToCanvas(
                                              device.offset +
                                                  Offset(
                                                    details.delta.dx /
                                                        canvasSize.width,
                                                    details.delta.dy /
                                                        canvasSize.height,
                                                  ),
                                              canvasSize,
                                            );
                                          });
                                        },
                                        child: Column(
                                          children: [
                                            IconButton(
                                              mouseCursor:
                                                  SystemMouseCursors.click,
                                              onPressed: () {
                                                _showAddDeviceDialog(
                                                  context,
                                                  device,
                                                );
                                              },
                                              icon: SvgPicture.asset(
                                                iconForType(device.type),
                                                width: 80.0,
                                                height: 80.0,
                                                colorFilter: ColorFilter.mode(
                                                  Colors.white,
                                                  BlendMode.srcIn,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              device.deviceName ?? "",
                                              style: Theme.of(
                                                context,
                                              ).textTheme.labelLarge,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                AnimatedContainer(
                  duration: _drawerDuration,
                  curve: Curves.easeInOut,
                  height: _isHorizontalBarOpen
                      ? _horizontalSize
                      : _collapsedSize,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                  child: Row(
                    spacing: 100,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isHorizontalBarOpen) ...[
                            Flexible(
                              child: IconButton(
                                onPressed: () {},
                                icon: FaIcon(
                                  FontAwesomeIcons.eye,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Text(
                              "View mode",
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isHorizontalBarOpen) ...[
                            Flexible(
                              child: IconButton(
                                onPressed: () {},
                                icon: FaIcon(
                                  FontAwesomeIcons.penToSquare,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Text(
                              "Edit mode",
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ],
                      ),
                      SizedBox(width: 200),
                      Column(
                        spacing: 10,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isHorizontalBarOpen) ...[
                            Flexible(
                              child: PrimaryButton(
                                onPressed: _saveData,
                                isLoading: _isSaving,
                                label: "Save",
                              ),
                            ),
                            Flexible(
                              child: SecondaryButton(
                                onPressed: _isSaving
                                    ? null
                                    : () {
                                        Navigator.pop(context);
                                      },
                                label: "Cancel",
                              ),
                            ),
                          ],
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: Icon(
                            _isHorizontalBarOpen
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                          ),
                          color: primaryColor,
                          iconSize: 30,
                          onPressed: () {
                            setState(() {
                              _isHorizontalBarOpen = !_isHorizontalBarOpen;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// [isNew] is true right after a drop: cancelling then removes the device
  /// again instead of leaving an empty one on the canvas.
  Future<void> _showAddDeviceDialog(
    BuildContext context,
    _PlacedDevice device, {
    bool isNew = false,
  }) {
    final theme = Theme.of(context);

    final deviceNameController = TextEditingController(text: device.deviceName);
    final ipAddressController = TextEditingController(text: device.ipAddress);
    final subnetMaskController = TextEditingController(text: device.subnetMask);
    final vlanIdController = TextEditingController(text: device.vlanID);
    final osVersionController = TextEditingController(
      text: device.osAndVersion,
    );
    final manufacturerController = TextEditingController(
      text: device.manufacturer,
    );
    final macAddressController = TextEditingController(text: device.macAdress);
    bool isChecked = false;
    return showDialog<_DeviceDialogResult>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: SizedBox(
              width: 1000,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 10,
                  children: [
                    const SizedBox(height: 50),
                    PrimaryButton(
                      onPressed: () {},
                      label: "Generate enrollment token",
                      width: 250,
                    ),
                    const SizedBox(
                      width: 300,
                      child: CustomTextField(readOnly: true),
                    ),
                    const SizedBox(height: 50),
                    Row(
                      spacing: 20,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextField(
                                controller: deviceNameController,
                                labelText: "Device name",
                              ),
                              const SizedBox(height: 15),
                              CustomTextField(
                                controller: ipAddressController,
                                labelText: "IP address",
                              ),
                              const SizedBox(height: 15),
                              CustomTextField(
                                controller: subnetMaskController,
                                labelText: "Subnetmask",
                              ),
                              const SizedBox(height: 15),
                              CustomTextField(
                                controller: vlanIdController,
                                labelText: "VLAN ID",
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextField(
                                controller: osVersionController,
                                labelText: "OS and Version",
                              ),
                              const SizedBox(height: 15),
                              CustomTextField(
                                controller: manufacturerController,
                                labelText: "Manufacturer",
                              ),
                              const SizedBox(height: 15),
                              CustomTextField(
                                controller: macAddressController,
                                labelText: "MAC address",
                              ),
                              const SizedBox(height: 70),
                              Row(
                                spacing: 10,
                                children: [
                                  Checkbox(
                                    value: isChecked,
                                    side: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    onChanged: (bool? newValue) {
                                      setDialogState(() {
                                        isChecked = newValue ?? false;
                                      });
                                    },
                                  ),
                                  Text(
                                    "Device isn't a scout",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 80),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!isNew) ...[
                          SecondaryButton(
                            onPressed: () async {
                              final confirmed = await alertBox(
                                dialogContext,
                                "Delete device",
                                device.id == null
                                    ? "Remove this device from the office?"
                                    : "Remove this device from the office? "
                                          "When you save the office, its "
                                          "report history is deleted too.",
                                mode: AlertBoxMode.choice,
                              );
                              if (confirmed != true || !dialogContext.mounted) {
                                return;
                              }
                              Navigator.of(
                                dialogContext,
                              ).pop(const _DeviceDialogResult.delete());
                            },
                            label: "Delete device",
                            width: 180,
                          ),
                          const Spacer(),
                        ],
                        SecondaryButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          label: "Cancel",
                        ),
                        const SizedBox(width: 12),
                        PrimaryButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(
                              _DeviceDialogResult.save(
                                _PlacedDevice(
                                  type: device.type,
                                  offset: device.offset,
                                  deviceName: deviceNameController.text,
                                  ipAddress: ipAddressController.text,
                                  subnetMask: subnetMaskController.text,
                                  vlanID: vlanIdController.text,
                                  osAndVersion: osVersionController.text,
                                  manufacturer: manufacturerController.text,
                                  macAdress: macAddressController.text,
                                ),
                              ),
                            );
                          },
                          label: "Save",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).then((dialogResult) {
      if (!mounted) return;
      if (dialogResult == null) {
        if (isNew) setState(() => _placedDevices.remove(device));
        return;
      }
      if (dialogResult.delete) {
        setState(() => _placedDevices.remove(device));
        return;
      }
      final result = dialogResult.device!;
      setState(() {
        device.deviceName = result.deviceName;
        device.ipAddress = result.ipAddress;
        device.subnetMask = result.subnetMask;
        device.vlanID = result.vlanID;
        device.osAndVersion = result.osAndVersion;
        device.manufacturer = result.manufacturer;
        device.macAdress = result.macAdress;
      });
    });
  }

  Future<String?> _showOfficeName(BuildContext context, String officeName) {
    final theme = Theme.of(context);
    final officeNameController = TextEditingController(text: officeName);
    final formKey = GlobalKey<FormState>();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: theme.colorScheme.surface,
          insetPadding: EdgeInsets.all(10),
          child: SizedBox(
            width: 400,
            height: 400,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 10,
                children: [
                  Text(
                    "Please insert office name",
                    style: theme.textTheme.displayLarge,
                    textAlign: TextAlign.center,
                  ),
                  Form(
                    key: formKey,
                    child: CustomTextField(
                      controller: officeNameController,
                      // Same rules as the API's office validator.
                      validator: (value) {
                        final name = (value as String? ?? "").trim();
                        if (name.isEmpty) return "Office name is required";
                        if (name.length < 3) {
                          return "Office name must be at least 3 characters";
                        }
                        if (name.length > 20) {
                          return "Office name can be at most 20 characters";
                        }
                        return null;
                      },
                    ),
                  ),
                  Row(
                    spacing: 10,
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            Navigator.pop(
                              context,
                              officeNameController.text.trim(),
                            );
                          },
                          label: "Save",
                        ),
                      ),
                      Expanded(
                        child: SecondaryButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          label: "Cancel",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
