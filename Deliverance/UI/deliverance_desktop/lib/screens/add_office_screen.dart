import 'package:deliverance_desktop/models/office.dart';
import 'package:deliverance_desktop/providers/office_provider.dart';
import 'package:deliverance_desktop/utils/api_client_exception.dart';
import 'package:deliverance_desktop/utils/util_widgets.dart';
import 'package:deliverance_desktop/widgets/custom_toast.dart';
import 'package:deliverance_desktop/widgets/office_editor/device_dialog.dart';
import 'package:deliverance_desktop/widgets/office_editor/device_palette.dart';
import 'package:deliverance_desktop/widgets/office_editor/office_editor_canvas.dart';
import 'package:deliverance_desktop/widgets/office_editor/office_editor_toolbar.dart';
import 'package:deliverance_desktop/widgets/office_editor/office_name_dialog.dart';
import 'package:deliverance_desktop/widgets/office_editor/placed_device.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Office editor, used both to add a new office and, with [office], to edit
/// an existing one.
///
/// How an office is built:
/// 1. Drag a device type from the [DevicePalette] onto the
///    [OfficeEditorCanvas].
/// 2. The device dialog opens to fill in its details and, optionally, enroll
///    a scout on it. Cancelling removes the dropped device again.
/// 3. Devices can be dragged around, or clicked to edit or delete them.
/// 4. Save in the [OfficeEditorToolbar] asks for the office name and sends
///    the whole office to the API. Pops with `true` once saved.
class AddOfficeScreen extends StatefulWidget {
  final Office? office;

  const AddOfficeScreen({super.key, this.office});

  @override
  State<AddOfficeScreen> createState() => _AddOfficeScreenState();
}

class _AddOfficeScreenState extends State<AddOfficeScreen> {
  late String _officeName = widget.office?.name ?? "";
  late final List<PlacedDevice> _devices = [
    for (final device in widget.office?.devices ?? <Devices>[])
      PlacedDevice.fromDevice(device),
  ];
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  bool get _isEditing => widget.office != null;

  Future<DeviceDialogResult?> _openDeviceDialog(
    PlacedDevice device, {
    required bool isNew,
  }) {
    return showDeviceDialog(
      context,
      device: device,
      isNew: isNew,
      otherDevices: _devices.where((other) => other != device).toList(),
      onScoutChanged: (scout) {
        if (mounted) setState(() => device.scout = scout);
      },
    );
  }

  Future<void> _addDevice(String type, Offset position) async {
    final device = PlacedDevice(type: type, position: position);
    setState(() => _devices.add(device));

    final result = await _openDeviceDialog(device, isNew: true);
    if (!mounted) return;
    setState(() {
      if (result is DeviceSaved) {
        device.details = result.details;
        _hasUnsavedChanges = true;
      } else {
        // Cancelled: don't leave an empty device on the canvas.
        _devices.remove(device);
      }
    });
  }

  Future<void> _editDevice(PlacedDevice device) async {
    final result = await _openDeviceDialog(device, isNew: false);
    if (!mounted) return;
    switch (result) {
      case DeviceSaved(:final details) when details != device.details:
        setState(() {
          device.details = details;
          _hasUnsavedChanges = true;
        });
      case DeviceDeleted():
        setState(() {
          _devices.remove(device);
          _hasUnsavedChanges = true;
        });
      default:
        break;
    }
  }

  void _moveDevice(PlacedDevice device, Offset position) {
    setState(() {
      device.position = position;
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final officeProvider = context.read<OfficeProvider>();
    final name = await showOfficeNameDialog(context, _officeName);
    if (name == null || !mounted) return;
    setState(() {
      _officeName = name;
      _isSaving = true;
    });

    final officeJson = Office(
      name: name,
      devices: [for (final device in _devices) device.toDevice(name)],
    ).toJson();
    try {
      if (_isEditing) {
        await officeProvider.update(widget.office!.id!, officeJson);
      } else {
        // A new office and its devices don't have ids yet.
        officeJson.remove('id');
        for (final device in officeJson['devices'] as List<dynamic>) {
          (device as Map<String, dynamic>).remove('id');
        }
        await officeProvider.insert(officeJson);
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

  /// Cancel goes through here; a successful save pops directly.
  Future<void> _onPopRequested(bool didPop, Object? _) async {
    if (didPop) return;
    final discard = await alertBox(
      context,
      "Discard changes?",
      "You have unsaved changes to this office. "
          "Are you sure you want to exit?",
      mode: AlertBoxMode.choice,
    );
    if (discard == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: _onPopRequested,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DevicePalette(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: OfficeEditorCanvas(
                      devices: _devices,
                      onDeviceDropped: _addDevice,
                      onDeviceMoved: _moveDevice,
                      onDeviceTapped: _editDevice,
                    ),
                  ),
                  OfficeEditorToolbar(
                    onSave: _save,
                    onCancel: _isSaving
                        ? null
                        : () => Navigator.maybePop(context),
                    isSaving: _isSaving,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
