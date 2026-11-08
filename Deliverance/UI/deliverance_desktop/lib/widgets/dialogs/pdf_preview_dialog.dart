import 'dart:io';
import 'dart:typed_data';

import 'package:deliverance_desktop/widgets/custom_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// Shows a PDF with a print button and a save button.
Future<void> showPdfPreviewDialog(
  BuildContext context, {
  required String title,
  required String fileName,
  required Uint8List bytes,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      final size = MediaQuery.sizeOf(dialogContext);

      return Dialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        child: SizedBox(
          width: size.width * 0.8,
          height: size.height * 0.9,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(title, style: theme.textTheme.headlineMedium),
                    ),
                    IconButton(
                      tooltip: "Close",
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: Icon(Icons.close, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PdfPreview(
                  // The server already laid the pages out, so the page format is ignored.
                  build: (_) async => bytes,
                  pdfFileName: fileName,
                  allowSharing: false,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  actions: [
                    PdfPreviewAction(
                      icon: const Icon(Icons.save_alt),
                      onPressed: (context, _, _) =>
                          _savePdf(context, fileName, bytes),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _savePdf(
  BuildContext context,
  String fileName,
  Uint8List bytes,
) async {
  try {
    final saved = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/pdf',
      dialogTitle: "Save PDF",
    );
    if (saved == null || !context.mounted) return;
    showCustomToast(
      context,
      "Saved to ${saved.toFilePath()}",
      type: ToastType.success,
    );
  } on FileSystemException catch (e) {
    if (!context.mounted) return;
    showCustomToast(
      context,
      "Could not save the PDF: ${e.message}",
      type: ToastType.error,
    );
  }
}
