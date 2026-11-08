import 'package:deliverance_scout/providers/scout_auth_provider.dart';
import 'package:deliverance_scout/providers/scout_enrollment_provider.dart';
import 'package:deliverance_scout/providers/scout_provider.dart';
import 'package:deliverance_scout/screens/awaiting_approval_screen.dart';
import 'package:deliverance_scout/screens/enrollment_screen.dart';
import 'package:deliverance_scout/screens/scout_disabled_screen.dart';
import 'package:deliverance_scout/screens/scout_home_screen.dart';
import 'package:deliverance_scout/themes/font_theme.dart';
import 'package:deliverance_scout/utils/util_widgets.dart';
import 'package:deliverance_scout/widgets/scout_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ScoutAuthProvider()..initialize(),
        ),
        ChangeNotifierProvider(create: (_) => ScoutEnrollmentProvider()),
        ChangeNotifierProvider(
          create: (context) => ScoutProvider(context.read<ScoutAuthProvider>()),
        ),
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
      title: 'Deliverance Scout',
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
      home: const ScoutGate(),
    );
  }
}

class ScoutGate extends StatelessWidget {
  const ScoutGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ScoutAuthProvider>();
    return switch (auth.state) {
      ScoutState.loading => ScoutPage(
        message: auth.message,
        isError: true,
        children: [globalLoadingSpinner()],
      ),
      ScoutState.unenrolled => const EnrollmentScreen(),
      ScoutState.awaitingApproval => const AwaitingApprovalScreen(),
      ScoutState.active => const ScoutHomeScreen(),
      ScoutState.disabled => const ScoutDisabledScreen(),
    };
  }
}
