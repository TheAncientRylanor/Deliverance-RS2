import 'package:deliverance_desktop/models/user.dart';
import 'package:deliverance_desktop/providers/selected_report_provider.dart';
import 'package:deliverance_desktop/providers/user_provider.dart';
import 'package:deliverance_desktop/screens/home_screen.dart';
import 'package:deliverance_desktop/screens/my_profile_screen.dart';
import 'package:deliverance_desktop/screens/offices_screen.dart';
import 'package:deliverance_desktop/screens/reports_history.dart';
import 'package:deliverance_desktop/screens/reports_screen.dart';
import 'package:deliverance_desktop/screens/single_report_screen.dart';
import 'package:deliverance_desktop/screens/statistics_screen.dart';
import 'package:deliverance_desktop/screens/user_profiles_sceen.dart';
import 'package:deliverance_desktop/utils/api_constants.dart';
import 'package:deliverance_desktop/widgets/chat_bot_button.dart';
import 'package:deliverance_desktop/widgets/image_holder.dart';
import 'package:deliverance_desktop/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Returns whether the user may leave the current screen.
typedef LeaveGuard = Future<bool> Function();

class MasterScreen extends StatefulWidget {
  const MasterScreen({super.key, required this.child, required this.title});
  final Widget child;
  final String title;
  @override
  State<MasterScreen> createState() => _MasterScreenState();

  /// Lets the child screen confirm or cancel sidebar navigation. The child
  /// lives on the same route as its MasterScreen, so it never has to
  /// unregister the guard.
  static void setLeaveGuard(BuildContext context, LeaveGuard? guard) {
    context.findAncestorStateOfType<_MasterScreenState>()?._leaveGuard = guard;
  }
}

class _MasterScreenState extends State<MasterScreen> {
  LeaveGuard? _leaveGuard;

  bool checkTitle(String activeTitle, String titleName) {
    return activeTitle.toLowerCase() == titleName.toLowerCase();
  }

  Widget _buildScreenForTitle(String titleName) {
    switch (titleName.trim().toLowerCase()) {
      case 'home':
        return const HomeScreen();
      case 'active reports':
        return MasterScreen(
          title: "Active reports",
          child: const ReportsScreen(),
        );
      case 'offices':
        return const OfficesScreen();
      case 'my profile':
        return MasterScreen(
          title: "My profile",
          child: const MyProfileScreen(),
        );
      case 'users':
        return MasterScreen(title: "Users", child: const UserProfilesSceen());
      case 'single report':
        final report = context.read<SelectedReportProvider>().report;
        if (report == null) {
          return const ReportsScreen();
        }
        return MasterScreen(
          title: "Single report",
          child: SingleReportScreen(report: report),
        );
      case 'statistics':
        return MasterScreen(title: "Statistics", child: StatisticsScreen());
      case 'reports history':
        return MasterScreen(title: "Reports history", child: ReportsHistory());
      default:
        return const HomeScreen();
    }
  }

  Future<void> _navigateTo(String titleName) async {
    final guard = _leaveGuard;
    if (guard != null && !await guard()) return;
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (checkTitle(titleName, "Single report") &&
        checkTitle(widget.title, "Single device") &&
        navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => _buildScreenForTitle(titleName)),
      (route) => false,
    );
  }

  Widget _buildButtonClass(
    String activeTitle,
    String titleName, {
    double height = 40,
    double fontSize = 22,
    bool isEnabled = true,
  }) {
    if (checkTitle(activeTitle, titleName)) {
      // Already on this screen, so the button is disabled to avoid reloading it.
      return FilledButton(
        onPressed: null,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.all(0.0),
          fixedSize: Size(double.infinity, height),
          backgroundColor: Theme.of(context).colorScheme.outline,
          disabledBackgroundColor: Theme.of(context).colorScheme.outline,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(5),
          ),
          side: BorderSide(color: Theme.of(context).colorScheme.surface),
        ),
        child: Text(
          titleName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: fontSize,
            fontWeight: FontWeight(400),
          ),
        ),
      );
      // ignore: curly_braces_in_flow_control_structures
    } else {
      return OutlinedButton(
        onPressed: !isEnabled
            ? null
            : () {
                _navigateTo(titleName);
              },
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.all(0.0),
          fixedSize: Size(double.infinity, height),
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
            fontSize: fontSize,
            fontWeight: FontWeight(400),
          ),
        ),
      );
    }
  }

  Widget _buildProfileSection(BuildContext context, User? userData, Widget? _) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ProfileAvatar(
          isEditable: false,
          onEditTap: () {},
          width: 200,
          height: 200,
          child: buildProfileImage(
            null,
            userData?.imagePath ?? "",
            ApiConstants.baseUrl,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          userData?.username ?? "",
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }

  Widget _buildNavButtons(BuildContext context, String activeTitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: _buildButtonClass(activeTitle, "Home"),
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: _buildButtonClass(activeTitle, "My profile"),
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: _buildButtonClass(activeTitle, "Active reports"),
        ),
        if (widget.title == "Single report" || widget.title == "Single device")
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 55,
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 44,
                    child: CustomPaint(
                      painter: _ElbowConnectorPainter(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildButtonClass(
                      activeTitle,
                      "Single report",
                      height: 34,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (widget.title == "Single device")
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  SizedBox(
                    width: 74,
                    height: 44,
                    child: CustomPaint(
                      painter: _ElbowConnectorPainter(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildButtonClass(
                      activeTitle,
                      "Single device",
                      height: 36,
                      fontSize: 16,
                      isEnabled: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: _buildButtonClass(activeTitle, "Statistics"),
        ),
        if (widget.title == "Critical device")
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  SizedBox(
                    width: 74,
                    height: 42,
                    child: CustomPaint(
                      painter: _ElbowConnectorPainter(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildButtonClass(
                      activeTitle,
                      "Critical device",
                      height: 36,
                      fontSize: 16,
                      isEnabled: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: _buildButtonClass(activeTitle, "Offices"),
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: _buildButtonClass(activeTitle, "Users"),
        ),
        if (widget.title == "Single user")
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  SizedBox(
                    width: 74,
                    height: 42,
                    child: CustomPaint(
                      painter: _ElbowConnectorPainter(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildButtonClass(
                      activeTitle,
                      "Single user",
                      height: 36,
                      fontSize: 16,
                      isEnabled: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: _buildButtonClass(activeTitle, "Reports history"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Row(
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Selector<UserProvider, User?>(
                            selector: (_, userProvider) => userProvider.data,
                            builder: _buildProfileSection,
                          ),
                          const SizedBox(height: 40),
                          // Highlight follows the screen being shown, so it
                          // stays right after going back or logging in again.
                          _buildNavButtons(context, widget.title),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
          // Above the screen's content, so the chat is reachable everywhere.
          const Positioned(right: 20, bottom: 20, child: ChatBotButton()),
        ],
      ),
    );
  }
}

class _ElbowConnectorPainter extends CustomPainter {
  final Color color;
  const _ElbowConnectorPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final x = size.width / 2;
    final midY = size.height / 2;

    final path = Path()
      ..moveTo(x, -10)
      ..lineTo(x, midY)
      ..lineTo(size.width, midY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ElbowConnectorPainter oldDelegate) =>
      oldDelegate.color != color;
}
