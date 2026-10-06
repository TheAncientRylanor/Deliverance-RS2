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

const List<String> _reportLabels = [
  'From:',
  'Title:',
  'Date Sent:',
  'Severity:',
];

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

  @override
  Widget build(BuildContext context) {
    final reportValues = [
      widget.report.user?.username ?? '-',
      widget.report.reportName ?? '-',
      _formattedDate,
      _severityLabel,
    ];

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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: _reportLabels
                                    .map(
                                      (label) => Text(
                                        label,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    )
                                    .toList(),
                              ),
                              SizedBox(width: 3),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: reportValues
                                    .map(
                                      (value) => Text(
                                        value,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w100,
                                            ),
                                      ),
                                    )
                                    .toList(),
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
