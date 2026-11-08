import 'package:deliverance_desktop/providers/auth_provider.dart';
import 'package:deliverance_desktop/providers/chat_bot_provider.dart';
import 'package:deliverance_desktop/providers/device_provider.dart';
import 'package:deliverance_desktop/providers/execution_command_provider.dart';
import 'package:deliverance_desktop/providers/notification_provider.dart';
import 'package:deliverance_desktop/providers/office_provider.dart';
import 'package:deliverance_desktop/providers/pdf_report_provider.dart';
import 'package:deliverance_desktop/providers/recommendation_provider.dart';
import 'package:deliverance_desktop/providers/report_provider.dart';
import 'package:deliverance_desktop/providers/report_statistics_provider.dart';
import 'package:deliverance_desktop/providers/scout_command_provider.dart';
import 'package:deliverance_desktop/providers/scout_enrollment_provider.dart';
import 'package:deliverance_desktop/providers/selected_report_provider.dart';
import 'package:deliverance_desktop/providers/selected_user_provider.dart';
import 'package:deliverance_desktop/providers/user_provider.dart';
import 'package:deliverance_desktop/screens/home_screen.dart';
import 'package:deliverance_desktop/themes/fontTheme.dart';
import 'package:deliverance_desktop/utils/api_client_exception.dart';
import 'package:deliverance_desktop/utils/navigation_service.dart';
import 'package:deliverance_desktop/utils/util_widgets.dart';
import 'package:deliverance_desktop/widgets/custom_buttons.dart';
import 'package:deliverance_desktop/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OfficeProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ReportStatisticsProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationProvider()),
        ChangeNotifierProvider(create: (_) => SelectedReportProvider()),
        ChangeNotifierProvider(create: (_) => SelectedUserProvider()),
        ChangeNotifierProvider(create: (_) => ExecutionCommandProvider()),
        ChangeNotifierProvider(create: (_) => ScoutEnrollmentProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => ScoutCommandProvider()),
        ChangeNotifierProvider(create: (_) => ChatBotProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => PdfReportProvider()),
      ],

      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      navigatorKey: navigatorKey,
      routes: {'/login': (context) => const LoginScreen()},
      localizationsDelegates:
          MonthYearPickerLocalizations.localizationsDelegates,
      supportedLocales: MonthYearPickerLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color.fromRGBO(26, 32, 44, 1.00),
          surface: Color.fromRGBO(26, 32, 44, 1.00),
          onSurface: Colors.white,
          surfaceContainer: Color.fromRGBO(45, 55, 72, 1.00),
          primary: Color.fromRGBO(255, 179, 0, 1),
          secondary: Color.fromRGBO(26, 32, 44, 1.00),
          onPrimary: Color.fromRGBO(26, 32, 44, 1.00),
          onSecondary: Color.fromRGBO(255, 255, 255, 1.00),
          outline: Color.fromRGBO(255, 179, 0, 1.00),
        ),
        textTheme: createFontScheme(),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<AuthStatus> _authFuture;

  @override
  void initState() {
    super.initState();
    _authFuture = _initAuth();
  }

  Future<AuthStatus> _initAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final status = await authProvider.tryAutoLogin();
    if (status == AuthStatus.authenticated) {
      await userProvider.loadCurrentUser();
    }
    return status;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthStatus>(
      future: _authFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == AuthStatus.authenticated) {
          return HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoggingIn = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoggingIn) return;
    setState(() => _isLoggingIn = true);
    try {
      await context.read<AuthProvider>().login(
        _usernameController.text,
        _passwordController.text,
      );
      if (!mounted) return;
      await context.read<UserProvider>().loadCurrentUser();
      if (!mounted) return;
      // Replace the login screen so going back can't return to it.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } on ApiClientException catch (e) {
      if (!mounted) return;
      alertBox(context, "Login error", e.message);
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            padding: EdgeInsets.only(bottom: 70.0),
            constraints: BoxConstraints(maxHeight: 800, maxWidth: 400),
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 70.0),
                    child: Text(
                      "Ready to report?",
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    labelText: "Username",
                    controller: _usernameController,
                    onSubmited: (_) => _login(),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    obscureText: true,
                    labelText: "Password",
                    controller: _passwordController,
                    onSubmited: (_) => _login(),
                  ),
                  const SizedBox(height: 60),
                  PrimaryButton(
                    onPressed: _login,
                    isLoading: _isLoggingIn,
                    label: 'Log in',
                    width: 200,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
