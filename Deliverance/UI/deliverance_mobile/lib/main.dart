import 'package:deliverance_mobile/layouts/global_last_screen.dart';
import 'package:deliverance_mobile/layouts/master_screen.dart';
import 'package:deliverance_mobile/providers/auth_provider.dart';
import 'package:deliverance_mobile/providers/chat_bot_provider.dart';
import 'package:deliverance_mobile/providers/contact_provider.dart';
import 'package:deliverance_mobile/providers/occurrence_provider.dart';
import 'package:deliverance_mobile/providers/office_provider.dart';
import 'package:deliverance_mobile/providers/report_provider.dart';
import 'package:deliverance_mobile/providers/user_provider.dart';
import 'package:deliverance_mobile/screens/home_screen.dart';
import 'package:deliverance_mobile/screens/register_screen.dart';
import 'package:deliverance_mobile/themes/font_theme.dart';
import 'package:deliverance_mobile/utils/api_client_exception.dart';
import 'package:deliverance_mobile/utils/form_validators.dart';
import 'package:deliverance_mobile/utils/server_field_errors.dart';
import 'package:deliverance_mobile/utils/navigation_service.dart';
import 'package:deliverance_mobile/utils/util_widgets.dart';
import 'package:deliverance_mobile/widgets/custom_buttons.dart';
import 'package:deliverance_mobile/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
        ChangeNotifierProvider(create: (_) => GlobalData()),
        ChangeNotifierProvider(create: (_) => OfficeProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => OccurrenceProvider()),
        ChangeNotifierProvider(create: (_) => ChatBotProvider()),
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color.fromRGBO(26, 32, 44, 1.00),
          surface: Color.fromRGBO(26, 32, 44, 1.00),
          onSurface: Colors.white,
          surfaceContainer: Color.fromRGBO(45, 55, 72, 1.00),
          surfaceDim: Color.fromRGBO(31, 37, 49, 1),
          primary: Color.fromRGBO(255, 179, 0, 1.00),
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
    _authFuture = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).tryAutoLogin();
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
          return const MasterScreen(title: "Home", child: HomeScreen());
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ServerFieldErrors _serverErrors = ServerFieldErrors();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isCredentialsError(ApiClientException e) =>
      e.statusCode != null && e.statusCode! < 500;

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
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextField(
                          labelText: "Username",
                          controller: _usernameController,
                          validator: requiredField('Username'),
                        ),
                        const SizedBox(height: 28),
                        CustomTextField(
                          obscureText: _obscurePassword,
                          labelText: "Password",
                          controller: _passwordController,
                          validator: _serverErrors.wrap(
                            'Password',
                            requiredField('Password'),
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: Column(
                      children: [
                        SizedBox(height: 60),
                        PrimaryButton(
                          onPressed: () async {
                            AuthProvider authProvider =
                                Provider.of<AuthProvider>(
                                  context,
                                  listen: false,
                                );
                            _serverErrors.clear();
                            if (!_formKey.currentState!.validate()) return;
                            try {
                              await authProvider.login(
                                _usernameController.text,
                                _passwordController.text,
                              );
                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MasterScreen(
                                    title: "Home",
                                    child: HomeScreen(),
                                  ),
                                ),
                              );
                            } on ApiClientException catch (e) {
                              if (!context.mounted) return;
                              if (_isCredentialsError(e)) {
                                _serverErrors.set(
                                  'Password',
                                  e.message,
                                  _formKey,
                                );
                              } else {
                                alertBox(
                                  context,
                                  "Login error",
                                  e.toString(),
                                  mode: AlertBoxMode.ok,
                                );
                              }
                            }
                          },
                          label: 'Log in',
                        ),
                        const SizedBox(height: 20),
                        SecondaryButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterScreen(),
                              ),
                            );
                          },
                          label: 'Register',
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
    );
  }
}
