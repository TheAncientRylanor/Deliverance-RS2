import 'package:deliverance_desktop/models/report.dart';
import 'package:deliverance_desktop/models/search_result.dart';
import 'package:deliverance_desktop/widgets/report_card.dart';
import 'package:flutter/material.dart';

class ReportsChild extends StatefulWidget {
  final double? size;
  final SearchResult<Report> reportList;
  const ReportsChild({super.key, this.size, required this.reportList});

  @override
  State<ReportsChild> createState() => _ReportsChildState();
}

class _ReportsChildState extends State<ReportsChild> {
  int currentIndex = 0;

  @override
  void didUpdateWidget(covariant ReportsChild oldWidget) {
    super.didUpdateWidget(oldWidget);
    final itemCount = widget.reportList.items?.length ?? 0;
    if (currentIndex >= itemCount) {
      currentIndex = itemCount == 0 ? 0 : itemCount - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.reportList.items ?? [];
    final hasPrevious = currentIndex > 0;
    final hasNext = currentIndex < items.length - 1;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.primary),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotatedBox(
              quarterTurns: 2,
              child: IconButton(
                icon: Icon(Icons.arrow_forward_ios),
                color: Theme.of(context).colorScheme.primary,
                onPressed: hasPrevious
                    ? () {
                        setState(() {
                          currentIndex--;
                        });
                      }
                    : null,
                iconSize: 40,
              ),
            ),
            const SizedBox(width: 20),
            items.isNotEmpty
                ? ReportCard(report: items[currentIndex])
                : const SizedBox(width: 50),
            const SizedBox(width: 20),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios),
              color: Theme.of(context).colorScheme.primary,
              onPressed: hasNext
                  ? () {
                      setState(() {
                        currentIndex++;
                      });
                    }
                  : null,
              iconSize: 40,
            ),
          ],
        ),
      ),
    );
  }
}
