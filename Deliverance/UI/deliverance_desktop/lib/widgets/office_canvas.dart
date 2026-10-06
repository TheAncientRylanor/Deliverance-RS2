import 'package:deliverance_desktop/layouts/master_screen.dart';
import 'package:deliverance_desktop/models/office.dart';
import 'package:deliverance_desktop/screens/single_device_report_screen.dart';
import 'package:deliverance_desktop/utils/constants.dart';
import 'package:deliverance_desktop/widgets/device_details_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class OfficeCanvas extends StatelessWidget {
  final Office office;
  final Size canvasSize;
  final bool isReport;
  const OfficeCanvas({
    super.key,
    required this.office,
    required this.canvasSize,
    required this.isReport,
  });
  Column getDevice(BuildContext context, Devices device) {
    if (device.isReported ?? false) {
      return Column(
        children: [
          Stack(
            alignment: AlignmentGeometry.topCenter,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -17,
                child: Icon(
                  Icons.warning,
                  size: 30,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              IconButton(
                mouseCursor: SystemMouseCursors.click,
                onPressed: () {
                  if (isReport) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MasterScreen(
                          title: "Single device",
                          child: SingleDeviceReportScreen(
                            device: device,
                            officeName: office.name ?? "",
                          ),
                        ),
                      ),
                    );
                  } else {
                    showDeviceDetailsDialog(context, device);
                  }
                },
                icon: SvgPicture.asset(
                  iconForType((device.type as String)),
                  width: 80.0,
                  height: 80.0,
                  colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
              Positioned(
                bottom: -6,
                child: Text(
                  device.name ?? "",
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Stack(
            alignment: AlignmentGeometry.topCenter,
            clipBehavior: Clip.none,
            children: [
              IconButton(
                mouseCursor: SystemMouseCursors.click,
                onPressed: () {
                  if (isReport) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MasterScreen(
                          title: "Single device",
                          child: SingleDeviceReportScreen(
                            device: device,
                            officeName: office.name ?? "",
                          ),
                        ),
                      ),
                    );
                  } else {
                    showDeviceDetailsDialog(context, device);
                  }
                },
                icon: SvgPicture.asset(
                  iconForType((device.type as String)),
                  width: 80.0,
                  height: 80.0,
                  colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
              Positioned(
                bottom: -6,
                child: Text(
                  device.name ?? "",
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (var device in office.devices ?? [])
          Positioned(
            left: device.positionX * canvasSize.width,
            top: device.positionY * canvasSize.height,
            child: getDevice(context, device),
          ),
      ],
    );
  }
}
