import 'package:deliverance_desktop/layouts/globalLastScreen.dart';
import 'package:deliverance_desktop/providers/auth_provider.dart';
import 'package:deliverance_desktop/providers/office_provider.dart';
import 'package:deliverance_desktop/screens/home_screen.dart';
import 'package:deliverance_desktop/themes/fontTheme.dart';
import 'package:deliverance_desktop/utils/api_client_exception.dart';
import 'package:deliverance_desktop/utils/util_widgets.dart';
import 'package:deliverance_desktop/widgets/custom_buttons.dart';
import 'package:deliverance_desktop/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GlobalData()),
        ChangeNotifierProvider(create: (_) => OfficeProvider()),
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color.fromRGBO(26, 32, 44, 1.00),
          surface: Color.fromRGBO(26, 32, 44, 1.00),
          onSurface: Colors.white,
          surfaceContainer: Color.fromRGBO(45, 55, 72, 1.00),
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
          return HomeScreen();
        }
        return LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
                  SizedBox(height: 8),
                  CustomTextField(
                    labelText: "Username",
                    controller: _usernameController,
                  ),
                  SizedBox(height: 20),
                  SizedBox(height: 8),
                  CustomTextField(
                    obscureText: true,
                    labelText: "Password",
                    controller: _passwordController,
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
                            try {
                              await authProvider.login(
                                _usernameController.text,
                                _passwordController.text,
                              );
                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HomeScreen(),
                                ),
                              );
                            } on ApiClientException catch (e) {
                              alertBox(context, "Login error", e.toString());
                            }
                          },
                          label: 'Log in',
                        ),
                        SizedBox(height: 20),
                        SecondaryButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(),
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
