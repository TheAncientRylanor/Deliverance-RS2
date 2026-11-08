import 'package:deliverance_desktop/models/report.dart';
import 'package:deliverance_desktop/models/user.dart';
import 'package:deliverance_desktop/providers/notification_provider.dart';
import 'package:deliverance_desktop/providers/report_provider.dart';
import 'package:deliverance_desktop/providers/selected_report_provider.dart';
import 'package:deliverance_desktop/providers/selected_user_provider.dart';
import 'package:deliverance_desktop/providers/user_provider.dart';
import 'package:deliverance_desktop/screens/home_screen.dart';
import 'package:deliverance_desktop/screens/my_profile_screen.dart';
import 'package:deliverance_desktop/screens/offices_screen.dart';
import 'package:deliverance_desktop/screens/reports_history.dart';
import 'package:deliverance_desktop/screens/reports_screen.dart';
import 'package:deliverance_desktop/screens/single_report_screen.dart';
import 'package:deliverance_desktop/screens/single_user_screen.dart';
import 'package:deliverance_desktop/screens/statistics_screen.dart';
import 'package:deliverance_desktop/screens/user_profiles_screen.dart';
import 'package:deliverance_desktop/utils/api_client_exception.dart';
import 'package:deliverance_desktop/utils/api_constants.dart';
import 'package:deliverance_desktop/utils/util_widgets.dart';
import 'package:deliverance_desktop/widgets/chat_bot_button.dart';
import 'package:deliverance_desktop/widgets/image_holder.dart';
import 'package:deliverance_desktop/widgets/notification_bell.dart';
import 'package:deliverance_desktop/widgets/notification_panel.dart';
import 'package:deliverance_desktop/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

typedef LeaveGuard = Future<bool> Function();

class MasterScreen extends StatefulWidget {
  const MasterScreen({super.key, required this.child, required this.title});
  final Widget child;
  final String title;
  @override
  State<MasterScreen> createState() => _MasterScreenState();

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

  Future<void> _showNotifications() async {
    final notification = await showNotificationPanel(context);
    if (notification == null || !mounted) return;

    try {
      await context.read<NotificationProvider>().markAsRead(notification.id);
    } catch (_) {}

    final reportId = notification.reportId;
    final userId = notification.relatedUserUUID;
    if (reportId == null && userId == null) return;

    final guard = _leaveGuard;
    if (guard != null && !await guard()) return;

    if (reportId != null) {
      await _openReport(reportId);
    } else if (userId != null) {
      await _openUser(userId);
    }
  }

  Future<void> _openReport(int id) async {
    if (!mounted) return;
    final Report report;
    try {
      report = await context.read<ReportProvider>().getById(id);
    } catch (e) {
      _showUnavailable(e, "report");
      return;
    }
    if (!mounted) return;

    context.read<SelectedReportProvider>().select(report);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MasterScreen(
          title: "Single report",
          child: SingleReportScreen(report: report),
        ),
      ),
    );
  }

  Future<void> _openUser(String id) async {
    if (!mounted) return;
    final User user;
    try {
      user = await context.read<UserProvider>().getByUUID(
        id,
        isCurrentUser: false,
      );
    } catch (e) {
      _showUnavailable(e, "user");
      return;
    }
    if (!mounted) return;

    context.read<SelectedUserProvider>().select(user);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MasterScreen(
          title: "Single user",
          child: SingleUserScreen(user: user),
        ),
      ),
    );
  }

  void _showUnavailable(Object error, String item) {
    if (!mounted) return;
    final isMissing = error is ApiClientException && error.isNotFound;
    alertBox(
      context,
      isMissing ? "This $item no longer exists" : "Couldn't open this $item",
      isMissing
          ? "It may have been deleted, so there's nothing to show."
          : "We couldn't load it right now. Please check your connection and try again in a moment.",
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
          const Positioned(right: 20, bottom: 20, child: ChatBotButton()),
          Positioned(
            right: 20,
            top: 20,
            child: NotificationBell(onPressed: _showNotifications),
          ),
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
