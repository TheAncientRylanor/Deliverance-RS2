import 'package:deliverance_desktop/layouts/globalLastScreen.dart';
import 'package:deliverance_desktop/screens/home_screen.dart';
import 'package:deliverance_desktop/screens/offices_screen.dart';
import 'package:deliverance_desktop/screens/reports_screen.dart';
import 'package:deliverance_desktop/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MasterScreen extends StatefulWidget {
  const MasterScreen({super.key, required this.child, required this.title});
  final Widget child;
  final String title;
  @override
  State<MasterScreen> createState() => _MasterScreenState();
}

class _MasterScreenState extends State<MasterScreen> {
  bool checkTitle(GlobalData globalData, String titleName) {
    return globalData.lastScreenName == titleName.toLowerCase();
  }

  Widget _buildScreenForTitle(GlobalData globalData, String titleName) {
    switch (titleName.trim().toLowerCase()) {
      case 'home':
        return const HomeScreen();
      case 'active reports':
        return const ReportsScreen();
      case 'offices':
        return const OfficesScreen();
      default:
        return const HomeScreen();
    }
  }

  Widget _buildButtonClass(String titleName) {
    final globalData = context.watch<GlobalData>();
    if (checkTitle(globalData, titleName)) {
      return FilledButton(
        onPressed: () {
          globalData.updateWidget(titleName.toLowerCase());
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _buildScreenForTitle(globalData, titleName),
            ),
          );
        },
        style: FilledButton.styleFrom(
          padding: EdgeInsets.all(0.0),
          fixedSize: Size(double.infinity, 40),
          backgroundColor: Theme.of(context).colorScheme.outline,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(5),
          ),
          side: BorderSide(color: Theme.of(context).colorScheme.surface),
        ),
        child: Text(
          titleName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 22,
            fontWeight: FontWeight(400),
          ),
        ),
      );
      // ignore: curly_braces_in_flow_control_structures
    } else {
      return OutlinedButton(
        onPressed: () {
          globalData.updateWidget(titleName.toLowerCase());
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _buildScreenForTitle(globalData, titleName),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.all(0.0),
          fixedSize: Size(double.infinity, 40),
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(5),
          ),
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        child: Text(
          titleName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight(400),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ProfileAvatar(
                    isEditable: false,
                    onEditTap: () {},
                    child: Icon(Icons.person, size: 140.0, color: Colors.white),
                    height: 240,
                    width: 240,
                    containerHeight: 200,
                    containerWidth: 200,
                  ),
                  Text(
                    "Admin1",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 40),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: _buildButtonClass("Home"),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: _buildButtonClass("My profile"),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: _buildButtonClass("Active reports"),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: _buildButtonClass("Statistics"),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: _buildButtonClass("Offices"),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: _buildButtonClass("Users"),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: _buildButtonClass("Reports history"),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
