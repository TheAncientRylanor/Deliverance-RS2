import 'package:deliverance_mobile/layouts/globalLastScreen.dart';
import 'package:deliverance_mobile/screens/contacts_screen.dart';
import 'package:deliverance_mobile/screens/home_screen.dart';
import 'package:deliverance_mobile/screens/my_profile_screen.dart';
import 'package:deliverance_mobile/screens/report_screen.dart';
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
  bool _isDrawerOpen = false;

  bool checkTitle(GlobalData globalData, String titleName) {
    return globalData.lastScreenName == titleName.toLowerCase();
  }

  Widget _buildScreenForTitle(GlobalData globalData, String titleName) {
    switch (titleName.trim().toLowerCase()) {
      case 'home':
        return const HomeScreen();
      case 'my profile':
        return const MyProfileScreen();
      case 'contacts':
        return const ContactsScreen();
      case 'add contacts':
        return const ContactsScreen();
      case 'report a problem':
        return const ReportScreen();
      default:
        return HomeScreen();
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
          padding: EdgeInsets.all(5.0),
          fixedSize: Size(250, double.infinity),
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
          padding: EdgeInsets.all(5.0),
          fixedSize: Size(250, double.infinity),
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
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: false,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          titleSpacing: 0,
          title: Visibility(
            visible: !_isDrawerOpen,
            child: SizedBox(
              width: double.infinity,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 56,
                      minHeight: 56,
                    ),
                    onPressed: () {
                      setState(() {
                        _isDrawerOpen = !_isDrawerOpen;
                      });
                    },
                    icon: Icon(
                      Icons.menu_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 70,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Padding(padding: EdgeInsets.only(top: 130), child: widget.child),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_isDrawerOpen,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                opacity: _isDrawerOpen ? 1 : 0,
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDrawerOpen = false;
                      });
                    },
                    child: Container(
                      color: Colors.black54,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: double.infinity,

                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        transform: Matrix4.translationValues(
                          0,
                          _isDrawerOpen ? 0 : -20,
                          0,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                title: Center(
                                  child: SizedBox(
                                    width: 250,
                                    child: _buildButtonClass("Home"),
                                  ),
                                ),
                              ),
                              ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                title: Center(
                                  child: SizedBox(
                                    width: 250,
                                    child: _buildButtonClass("My profile"),
                                  ),
                                ),
                              ),
                              ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                title: Center(
                                  child: SizedBox(
                                    width: 250,
                                    child: _buildButtonClass(
                                      "Report a problem",
                                    ),
                                  ),
                                ),
                              ),
                              ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                title: Center(
                                  child: SizedBox(
                                    width: 250,
                                    child: _buildButtonClass("History"),
                                  ),
                                ),
                              ),
                              ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                title: Center(
                                  child: SizedBox(
                                    width: 250,
                                    child: _buildButtonClass("Contacts"),
                                  ),
                                ),
                              ),
                              ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                title: Center(
                                  child: SizedBox(
                                    width: 250,
                                    child: _buildButtonClass("Help"),
                                  ),
                                ),
                              ),
                              ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                title: Center(
                                  child: SizedBox(
                                    width: 250,
                                    child: _buildButtonClass("Chatbot"),
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
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 80),
        child: Visibility(
          visible: _isDrawerOpen,
          child: FloatingActionButton.large(
            onPressed: () {},
            backgroundColor: Colors.transparent,
            elevation: 0.0,
            child: SizedBox(
              width: double.infinity,
              child: Center(
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 56,
                    minHeight: 56,
                  ),
                  onPressed: () {
                    setState(() {
                      _isDrawerOpen = !_isDrawerOpen;
                    });
                  },
                  icon: Icon(
                    Icons.menu_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 70,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
