import 'dart:typed_data';

import 'package:deliverance_desktop/providers/pdf_report_provider.dart';
import 'package:deliverance_desktop/utils/api_client_exception.dart';
import 'package:deliverance_desktop/widgets/custom_buttons.dart';
import 'package:deliverance_desktop/widgets/custom_date_time_picker.dart';
import 'package:deliverance_desktop/widgets/custom_drop_down.dart';
import 'package:deliverance_desktop/widgets/custom_text_field.dart';
import 'package:deliverance_desktop/widgets/dialogs/pdf_preview_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

final _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
final _fileDateFormat = DateFormat('yyyy-MM-dd');

/// Both dates are optional. The API then covers the 30 days up to now.
Future<void> showReportActivityPdfDialog(BuildContext context) {
  final provider = context.read<PdfReportProvider>();
  final fromController = TextEditingController();
  final toController = TextEditingController();
  DateTime? from;
  DateTime? to;

  Widget dateField(
    BuildContext context,
    StateSetter setDialogState, {
    required String label,
    required String hint,
    required TextEditingController controller,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    return CustomTextField(
      labelText: label,
      hintText: hint,
      readOnly: true,
      controller: controller,
      prefixIcon: const Icon(Icons.av_timer, size: 30, color: Colors.white),
      suffixIcon: value == null
          ? null
          : IconButton(
              tooltip: "Clear",
              onPressed: () => setDialogState(() {
                controller.text = "";
                onChanged(null);
              }),
              icon: const Icon(Icons.close, size: 30, color: Colors.white),
            ),
      onTap: () async {
        final picked = await pickDateAndTime(context, initialDate: value);
        if (picked == null) return;
        setDialogState(() {
          controller.text = _dateTimeFormat.format(picked);
          onChanged(picked);
        });
      },
    );
  }

  return _showPdfOptionsDialog(
    context,
    title: "Report activity",
    fileName: "report-activity-${_fileDateFormat.format(DateTime.now())}.pdf",
    validate: () => from != null && to != null && from!.isAfter(to!)
        ? "The start can't be after the end."
        : null,
    generate: () => provider.getReportActivity(from: from, to: to),
    buildFields: (context, setDialogState) => Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        dateField(
          context,
          setDialogState,
          label: "From (optional)",
          hint: "30 days before the end",
          controller: fromController,
          value: from,
          onChanged: (value) => from = value,
        ),
        dateField(
          context,
          setDialogState,
          label: "To (optional)",
          hint: "Now",
          controller: toController,
          value: to,
          onChanged: (value) => to = value,
        ),
      ],
    ),
  );
}

/// [offices] uses -1 for "All", as on the Statistics screen.
Future<void> showDeviceHealthPdfDialog(
  BuildContext context,
  Map<int?, String> offices,
) {
  final provider = context.read<PdfReportProvider>();
  int selectedOffice = -1;

  return _showPdfOptionsDialog(
    context,
    title: "Device health",
    fileName: "device-health-${_fileDateFormat.format(DateTime.now())}.pdf",
    generate: () => provider.getDeviceHealth(
      officeId: selectedOffice == -1 ? null : selectedOffice,
    ),
    buildFields: (context, setDialogState) => CustomDropDown<int?>(
      label: "Location (optional)",
      items: offices,
      initialValue: selectedOffice,
      onChanged: (value) => selectedOffice = value ?? -1,
    ),
  );
}

/// Asks for the report's options, then opens the generated PDF.
/// The dialog stays open on an error so the options can be changed.
Future<void> _showPdfOptionsDialog(
  BuildContext screenContext, {
  required String title,
  required String fileName,
  required Widget Function(BuildContext context, StateSetter setDialogState)
  buildFields,
  required Future<Uint8List> Function() generate,
  String? Function()? validate,
}) {
  bool isGenerating = false;
  String? errorMessage;

  return showDialog<void>(
    context: screenContext,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> onGenerate() async {
            final invalid = validate?.call();
            if (invalid != null) {
              setDialogState(() => errorMessage = invalid);
              return;
            }
            setDialogState(() {
              isGenerating = true;
              errorMessage = null;
            });
            try {
              final bytes = await generate();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (!screenContext.mounted) return;
              await showPdfPreviewDialog(
                screenContext,
                title: title,
                fileName: fileName,
                bytes: bytes,
              );
            } on ApiClientException catch (e) {
              if (!dialogContext.mounted) return;
              setDialogState(() {
                isGenerating = false;
                errorMessage = e.message;
              });
            }
          }

          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            title: Center(child: Text("$title PDF")),
            titleTextStyle: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            content: SizedBox(
              width: 440,
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 16,
                  children: [
                    buildFields(context, setDialogState),
                    if (errorMessage != null)
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      spacing: 12,
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            onPressed: isGenerating
                                ? null
                                : () => Navigator.pop(dialogContext),
                            label: "Cancel",
                          ),
                        ),
                        Expanded(
                          child: PrimaryButton(
                            isLoading: isGenerating,
                            onPressed: onGenerate,
                            label: "Generate",
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
    },
  );
}
