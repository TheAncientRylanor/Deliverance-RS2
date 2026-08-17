import 'package:deliverance_desktop/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';

const List<String> _reportLabels = [
  'From:',
  'Title:',
  'Date Sent:',
  'Severity:',
];

class ReportCard extends StatelessWidget {
  final VoidCallback? onAddPressed;
  final double width;
  final double height;

  const ReportCard({
    super.key,
    this.onAddPressed,
    this.width = 250,
    this.height = 320,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          elevation: 10,
          shadowColor: Colors.black,
          color: Theme.of(context).colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0),
            side: BorderSide(
              width: 5,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: SizedBox(
            height: height,
            width: width,
            child: Column(
              children: [
                ProfileAvatar(
                  isEditable: false,
                  onEditTap: () {},
                  child: Icon(Icons.person, size: 110),
                  width: 190,
                  height: 190,
                  containerHeight: 150,
                  containerWidth: 150,
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
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            )
                            .toList(),
                      ),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _reportLabels
                            .map(
                              (label) => Text(
                                label,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
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
        Positioned(
          top: -20,
          left: 205,
          child: FilledButton(
            onPressed: onAddPressed,
            style: FilledButton.styleFrom(
              shape: CircleBorder(),
              disabledBackgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: Padding(padding: EdgeInsets.all(30)),
          ),
        ),
      ],
    );
  }
}
