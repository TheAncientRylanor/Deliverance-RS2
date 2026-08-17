import 'package:deliverance_desktop/layouts/master_screen.dart';
import 'package:deliverance_desktop/widgets/report_card.dart';
import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreen();
}

class _ReportsScreen extends State<ReportsScreen> {
  int _pageSize = 4;

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: "Active reports",
      child: SingleChildScrollView(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 20,
                children: [
                  FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      shape: CircleBorder(),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: EdgeInsets.all(20),
                    ),
                    child: Icon(Icons.search, size: 50),
                  ),
                  FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      shape: CircleBorder(),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: EdgeInsets.all(20),
                    ),
                    child: Icon(Icons.sort, size: 50),
                  ),
                ],
              ),
              SizedBox(height: 80),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Wrap(
                  spacing: 40,
                  runSpacing: 30,
                  children: [for (int i = 0; i < 10; i++) ReportCard()],
                ),
              ),
              SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                  Text(
                    "1 of 1",
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  SizedBox(width: 20),
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () {},
                    iconSize: 40,
                  ),
                  SizedBox(width: 20),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _pageSize,
                        items: [4, 8, 16, 32]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _pageSize = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
