import 'package:deliverance_desktop/layouts/master_screen.dart';
import 'package:deliverance_desktop/models/report.dart';
import 'package:deliverance_desktop/models/report_state_enum.dart';
import 'package:deliverance_desktop/models/severity_enum.dart';
import 'package:deliverance_desktop/providers/selected_report_provider.dart';
import 'package:deliverance_desktop/screens/single_report_screen.dart';
import 'package:deliverance_desktop/utils/api_constants.dart';
import 'package:deliverance_desktop/widgets/image_holder.dart';
import 'package:deliverance_desktop/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReportCard extends StatefulWidget {
  final VoidCallback? onAddPressed;
  final double width;
  final double height;
  final Report report;

  const ReportCard({
    super.key,
    this.onAddPressed,
    this.width = 250,
    this.height = 320,
    required this.report,
  });

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  bool _hover = false;

  String get _formattedDate {
    final date = widget.report.dateReported;
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String get _severityLabel {
    final severity = widget.report.severity;
    if (severity == null) return '-';
    return SeverityEnum.fromValue(severity).label;
  }

  bool getStatus() {
    return widget.report.status != ReportStateEnum.unseen.label;
  }

  TableRow _buildReportRow(
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
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
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
    return AnimatedScale(
      scale: _hover ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                context.read<SelectedReportProvider>().select(widget.report);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MasterScreen(
                      title: "Single report",
                      child: SingleReportScreen(report: widget.report),
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
                      width: getStatus() ? 1 : 5,
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
                          child: buildProfileImage(
                            null,
                            widget.report.user?.imagePath,
                            ApiConstants.baseUrl,
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Table(
                              defaultVerticalAlignment:
                                  TableCellVerticalAlignment.middle,
                              columnWidths: const {
                                0: IntrinsicColumnWidth(),
                                1: IntrinsicColumnWidth(),
                              },
                              children: [
                                _buildReportRow(
                                  context,
                                  Icons.location_on_outlined,
                                  'From:',
                                  widget.report.user?.username ?? '-',
                                ),
                                _buildReportRow(
                                  context,
                                  Icons.edit_outlined,
                                  'Title:',
                                  widget.report.reportName ?? '-',
                                ),
                                _buildReportRow(
                                  context,
                                  Icons.calendar_today_outlined,
                                  'Date:',
                                  _formattedDate,
                                ),
                                _buildReportRow(
                                  context,
                                  Icons.warning_amber_rounded,
                                  'Severity:',
                                  _severityLabel,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (!getStatus())
            Positioned(
              top: -20,
              left: 205,
              child: FilledButton(
                onPressed: null,
                style: FilledButton.styleFrom(
                  shape: CircleBorder(),
                  disabledBackgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary,
                ),
                child: Padding(padding: EdgeInsets.all(30)),
              ),
            ),
        ],
      ),
    );
  }
}
