import 'package:deliverance_desktop/models/office.dart';
import 'package:deliverance_desktop/widgets/office_canvas.dart';
import 'package:flutter/material.dart';

class FullScreenOfficeMap extends StatelessWidget {
  final Office office;
  final Color backgroundColor;
  final Color iconColor;
  final bool isReport;

  const FullScreenOfficeMap({
    super.key,
    required this.office,
    required this.backgroundColor,
    required this.iconColor,
    required this.isReport,
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
                    isReport: isReport,
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
