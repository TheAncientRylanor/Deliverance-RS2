import 'package:deliverance_desktop/layouts/master_screen.dart';
import 'package:deliverance_desktop/models/device_recommendation.dart';
import 'package:deliverance_desktop/models/issue_enum.dart';
import 'package:deliverance_desktop/screens/critical_device_screen.dart';
import 'package:deliverance_desktop/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';

class CriticalDeviceCard extends StatefulWidget {
  final double width;
  final double height;
  final DeviceRecommendation device;

  const CriticalDeviceCard({
    super.key,
    this.width = 250,
    this.height = 320,
    required this.device,
  });

  @override
  State<CriticalDeviceCard> createState() => _CriticalDeviceCardState();
}

class _CriticalDeviceCardState extends State<CriticalDeviceCard> {
  bool _hover = false;

  IssueEnum get _issue => IssueEnum.fromValue(widget.device.likelyIssue);

  IconData get _issueIcon => switch (_issue) {
    IssueEnum.hardware => Icons.memory,
    IssueEnum.software => Icons.terminal,
    IssueEnum.both => Icons.build_circle_outlined,
  };

  TableRow _buildDeviceRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700);

    return TableRow(
      children: [
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(label, style: labelStyle),
              ],
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w100),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;

    return AnimatedScale(
      scale: _hover ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MasterScreen(
                  title: "Critical device",
                  child: CriticalDeviceScreen(device: device),
                ),
              ),
            );
          },
          onHover: (isHovering) {
            setState(() => _hover = isHovering);
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Card(
              elevation: 5,
              shadowColor: Colors.black,
              color: Theme.of(context).colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
                side: BorderSide(
                  width: 1,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              child: SizedBox(
                height: widget.height,
                width: widget.width,
                child: Column(
                  children: [
                    ProfileAvatar(
                      isEditable: false,
                      onEditTap: () {},
                      width: 190,
                      height: 190,
                      containerHeight: 150,
                      containerWidth: 150,
                      child: Icon(
                        _issueIcon,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Table(
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        columnWidths: const {
                          0: IntrinsicColumnWidth(),
                          // Takes what is left, so a long name is cut off
                          // instead of running past the card.
                          1: FlexColumnWidth(),
                        },
                        children: [
                          _buildDeviceRow(
                            context,
                            Icons.computer_outlined,
                            'Device:',
                            device.deviceName,
                          ),
                          _buildDeviceRow(
                            context,
                            Icons.location_on_outlined,
                            'Office:',
                            device.officeName,
                          ),
                          _buildDeviceRow(
                            context,
                            Icons.warning_amber_rounded,
                            'Fix probability:',
                            device.probabilityLabel,
                          ),
                          _buildDeviceRow(
                            context,
                            Icons.build_outlined,
                            'Likely issue:',
                            _issue.label,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
