import 'package:deliverance_desktop/models/office.dart';
import 'package:deliverance_desktop/widgets/custom_buttons.dart';
import 'package:deliverance_desktop/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

Future<void> showDeviceDetailsDialog(BuildContext context, Devices device) {
  final theme = Theme.of(context);

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
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
                            readOnly: true,
                            controller: TextEditingController(
                              text: device.name,
                            ),
                            labelText: "Device name",
                          ),
                          const SizedBox(height: 15),
                          CustomTextField(
                            readOnly: true,
                            controller: TextEditingController(
                              text: device.ipAddress,
                            ),
                            labelText: "IP address",
                          ),
                          const SizedBox(height: 15),
                          CustomTextField(
                            readOnly: true,
                            controller: TextEditingController(
                              text: device.subnetMask,
                            ),
                            labelText: "Subnetmask",
                          ),
                          const SizedBox(height: 15),
                          CustomTextField(
                            readOnly: true,
                            controller: TextEditingController(
                              text: device.vlanID,
                            ),
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
                            readOnly: true,
                            controller: TextEditingController(text: device.os),
                            labelText: "OS and Version",
                          ),
                          const SizedBox(height: 15),
                          CustomTextField(
                            readOnly: true,
                            controller: TextEditingController(
                              text: device.manufacturer,
                            ),
                            labelText: "Manufacturer",
                          ),
                          const SizedBox(height: 15),
                          CustomTextField(
                            readOnly: true,
                            controller: TextEditingController(
                              text: device.macAddress,
                            ),
                            labelText: "MAC address",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SecondaryButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      label: "Close",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
