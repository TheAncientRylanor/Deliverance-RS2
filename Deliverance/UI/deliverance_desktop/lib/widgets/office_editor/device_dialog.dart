import 'package:deliverance_desktop/models/office.dart';
import 'package:deliverance_desktop/models/scout_enrollment.dart';
import 'package:deliverance_desktop/providers/device_provider.dart';
import 'package:deliverance_desktop/utils/api_client_exception.dart';
import 'package:deliverance_desktop/utils/util_widgets.dart';
import 'package:deliverance_desktop/widgets/custom_buttons.dart';
import 'package:deliverance_desktop/widgets/custom_text_field.dart';
import 'package:deliverance_desktop/widgets/custom_toast.dart';
import 'package:deliverance_desktop/widgets/office_editor/office_validators.dart';
import 'package:deliverance_desktop/widgets/office_editor/placed_device.dart';
import 'package:deliverance_desktop/widgets/scout_enrollment_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

sealed class DeviceDialogResult {
  const DeviceDialogResult();
}

class DeviceSaved extends DeviceDialogResult {
  final DeviceDetails details;
  const DeviceSaved(this.details);
}

class DeviceDeleted extends DeviceDialogResult {
  const DeviceDeleted();
}

Future<DeviceDialogResult?> showDeviceDialog(
  BuildContext context, {
  required PlacedDevice device,
  required bool isNew,
  required List<PlacedDevice> otherDevices,
  required ValueChanged<Scout> onScoutChanged,
}) {
  return showDialog<DeviceDialogResult>(
    context: context,
    builder: (_) => _DeviceDialog(
      device: device,
      isNew: isNew,
      otherDevices: otherDevices,
      onScoutChanged: onScoutChanged,
    ),
  );
}

class _DeviceDialog extends StatefulWidget {
  final PlacedDevice device;
  final bool isNew;
  final List<PlacedDevice> otherDevices;
  final ValueChanged<Scout> onScoutChanged;

  const _DeviceDialog({
    required this.device,
    required this.isNew,
    required this.otherDevices,
    required this.onScoutChanged,
  });

  @override
  State<_DeviceDialog> createState() => _DeviceDialogState();
}

class _DeviceDialogState extends State<_DeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final DeviceDetails _initial = widget.device.details;
  late final _name = TextEditingController(text: _initial.name);
  late final _ipAddress = TextEditingController(text: _initial.ipAddress);
  late final _subnetMask = TextEditingController(text: _initial.subnetMask);
  late final _vlanId = TextEditingController(text: _initial.vlanID);
  late final _os = TextEditingController(text: _initial.os);
  late final _manufacturer = TextEditingController(text: _initial.manufacturer);
  late final _macAddress = TextEditingController(text: _initial.macAddress);

  late int? _enrollmentId = _initial.enrollmentId;
  late Scout? _scout = widget.device.scout;
  bool _isNotScout = false;
  bool _tokenGenerated = false;
  bool _isTogglingScout = false;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _ipAddress,
      _subnetMask,
      _vlanId,
      _os,
      _manufacturer,
      _macAddress,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  DeviceDetails get _editedDetails => DeviceDetails(
    name: DeviceDetails.clean(_name.text),
    ipAddress: DeviceDetails.clean(_ipAddress.text),
    subnetMask: DeviceDetails.clean(_subnetMask.text),
    vlanID: DeviceDetails.clean(_vlanId.text),
    os: DeviceDetails.clean(_os.text),
    manufacturer: DeviceDetails.clean(_manufacturer.text),
    macAddress: DeviceDetails.clean(_macAddress.text),
    enrollmentId: _isNotScout ? null : _enrollmentId,
  );

  bool get _hasUnsavedChanges => _tokenGenerated || _editedDetails != _initial;

  String? _validateUnique(
    String? value,
    String? Function(DeviceDetails) pick,
    String fieldName,
  ) {
    final cleaned = DeviceDetails.clean(value)?.toLowerCase();
    if (cleaned == null) return null;
    final taken = widget.otherDevices.any(
      (other) => pick(other.details)?.toLowerCase() == cleaned,
    );
    return taken ? "Another device in this office has this $fieldName" : null;
  }

  void _onScoutClaimed(ScoutEnrollment enrollment) {
    _enrollmentId = enrollment.id;
    void fill(TextEditingController controller, String? value) {
      if (value != null && value.isNotEmpty) controller.text = value;
    }

    if (_name.text.isEmpty) fill(_name, enrollment.hostname);
    fill(_ipAddress, enrollment.ipAddress);
    fill(_subnetMask, enrollment.subnetMask);
    fill(_vlanId, enrollment.vlanID);
    fill(_os, enrollment.os);
    fill(_manufacturer, enrollment.manufacturer);
    fill(_macAddress, enrollment.macAddress);
  }

  Future<void> _toggleScout() async {
    final scout = _scout!;
    final deviceProvider = context.read<DeviceProvider>();
    final deviceId = widget.device.id!;
    setState(() => _isTogglingScout = true);
    try {
      if (scout.isDisabled) {
        await deviceProvider.setEnabledScout(deviceId);
      } else {
        await deviceProvider.setDisableScout(deviceId);
      }
      final updated = Scout(
        id: scout.id,
        createdAt: scout.createdAt,
        isDisabled: !scout.isDisabled,
      );
      widget.onScoutChanged(updated);
      if (mounted) {
        setState(() => _scout = updated);
        showCustomToast(
          context,
          updated.isDisabled
              ? "Scout on ${widget.device.details.name ?? "this device"} disabled. It won't receive commands."
              : "Scout on ${widget.device.details.name ?? "this device"} enabled.",
          type: ToastType.success,
        );
      }
    } on ApiClientException catch (e) {
      if (mounted) alertBox(context, "Error", e.message);
    } finally {
      if (mounted) setState(() => _isTogglingScout = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await alertBox(
      context,
      "Delete device",
      widget.device.id == null
          ? "Remove this device from the office?"
          : "Remove this device from the office? "
                "A device that appears in reports can't be removed, so the "
                "report history stays intact; saving the office will say so.",
      mode: AlertBoxMode.choice,
    );
    if (confirmed != true || !mounted) return;
    Navigator.of(context).pop(const DeviceDeleted());
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(DeviceSaved(_editedDetails));
  }

  Future<void> _onPopRequested(bool didPop, Object? _) async {
    if (didPop) return;
    if (_hasUnsavedChanges) {
      final discard = await alertBox(
        context,
        "Discard changes?",
        "You have unsaved changes for this device. "
            "Are you sure you want to exit?",
        mode: AlertBoxMode.choice,
      );
      if (discard != true) return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String? Function(String?) validator,
  ) {
    return CustomTextField(
      controller: controller,
      labelText: label,
      validator: (value) => validator(value as String?),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope<DeviceDialogResult>(
      canPop: false,
      onPopInvokedWithResult: _onPopRequested,
      child: Dialog(
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 10,
                  children: [
                    const SizedBox(height: 50),
                    ScoutEnrollmentSection(
                      enabled: !_isNotScout,
                      onTokenGenerated: () => _tokenGenerated = true,
                      onClaimed: _onScoutClaimed,
                    ),
                    const SizedBox(height: 50),
                    _buildFields(theme),
                    const SizedBox(height: 80),
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFields(ThemeData theme) {
    return Row(
      spacing: 20,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            spacing: 15,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(
                _name,
                "Device name",
                (value) =>
                    validateDeviceName(value) ??
                    _validateUnique(value, (d) => d.name, "name"),
              ),
              _field(
                _ipAddress,
                "IP address",
                (value) =>
                    validateIpAddress(value) ??
                    _validateUnique(value, (d) => d.ipAddress, "IP address"),
              ),
              _field(_subnetMask, "Subnet mask", validateSubnetMask),
              _field(_vlanId, "VLAN ID", validateVlanId),
            ],
          ),
        ),
        Expanded(
          child: Column(
            spacing: 15,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(
                _os,
                "OS and Version",
                (value) => validateMaxLength50(value, "OS and Version"),
              ),
              _field(
                _manufacturer,
                "Manufacturer",
                (value) => validateMaxLength50(value, "Manufacturer"),
              ),
              _field(
                _macAddress,
                "MAC address",
                (value) =>
                    validateMacAddress(value) ??
                    _validateUnique(value, (d) => d.macAddress, "MAC address"),
              ),
              const SizedBox(height: 40),
              Row(
                spacing: 10,
                children: [
                  Checkbox(
                    value: _isNotScout,
                    side: BorderSide(color: theme.colorScheme.primary),
                    onChanged: (value) =>
                        setState(() => _isNotScout = value ?? false),
                  ),
                  Text(
                    "Device isn't a scout",
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    final scout = _scout;
    return Row(
      spacing: 12,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!widget.isNew) ...[
          SecondaryButton(
            onPressed: _delete,
            label: "Delete device",
            width: 180,
          ),
        ],
        if (scout != null)
          PrimaryButton(
            onPressed: _isTogglingScout ? null : _toggleScout,
            isLoading: _isTogglingScout,
            label: scout.isDisabled ? "Enable scout" : "Disable scout",
          ),
        const Spacer(),
        SecondaryButton(
          onPressed: () => Navigator.of(context).maybePop(),
          label: "Cancel",
        ),
        PrimaryButton(onPressed: _save, label: "Save"),
      ],
    );
  }
}
