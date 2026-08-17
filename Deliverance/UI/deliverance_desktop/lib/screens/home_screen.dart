import 'package:deliverance_desktop/layouts/master_screen.dart';
import 'package:deliverance_desktop/widgets/report_card.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: "Home",
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 10,
          children: [
            SizedBox(height: 50),
            Text(
              "Latest Reports",
              style: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(fontWeight: FontWeight(400)),
            ),
            SizedBox(height: 10),
            ReportsChild(),
            SizedBox(height: 50),
            Text(
              "Statistics",
              style: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(fontWeight: FontWeight(400)),
            ),
            SizedBox(height: 10),
            ReportsStatistics(),
          ],
        ),
      ),
    );
  }
}

class ReportsChild extends StatefulWidget {
  const ReportsChild({super.key});

  @override
  State<ReportsChild> createState() => _ReportsChild();
}

class _ReportsChild extends State<ReportsChild> {
  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.9,
      child: Container(
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
                  onPressed: () {},
                  iconSize: 40,
                ),
              ),
              SizedBox(width: 20),
              ReportCard(),
              SizedBox(width: 20),
              IconButton(
                icon: Icon(Icons.arrow_forward_ios),
                color: Theme.of(context).colorScheme.primary,
                onPressed: () {},
                iconSize: 40,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReportsStatistics extends StatefulWidget {
  const ReportsStatistics({super.key});

  @override
  State<ReportsStatistics> createState() => _ReportsStatistics();
}

class _ReportsStatistics extends State<ReportsStatistics> {
  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.9,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.primary),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Center(),
      ),
    );
  }
}
