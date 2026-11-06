import 'package:deliverance_scout/main.dart';
import 'package:deliverance_scout/providers/scout_auth_provider.dart';
import 'package:deliverance_scout/providers/scout_enrollment_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  // No initialize(): it would read secure storage and call the API.
  Widget app(ScoutState state) => MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => ScoutAuthProvider(initialState: state),
      ),
      ChangeNotifierProvider(create: (_) => ScoutEnrollmentProvider()),
    ],
    child: const MyApp(),
  );

  testWidgets('Unenrolled scout shows title, token field and enroll button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app(ScoutState.unenrolled));

    expect(find.text('Scout device of Deliverance'), findsOneWidget);
    expect(find.text('Enrollment token'), findsOneWidget);
    expect(find.text('Enroll'), findsOneWidget);
  });

  testWidgets('Enrolling without a token asks for one', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app(ScoutState.unenrolled));

    await tester.tap(find.text('Enroll'));
    await tester.pump();

    expect(
      find.text('Paste the enrollment token from the admin app first.'),
      findsOneWidget,
    );
  });

  testWidgets('Claimed scout waits for the admin', (WidgetTester tester) async {
    await tester.pumpWidget(app(ScoutState.awaitingApproval));

    expect(find.textContaining('Waiting for the admin'), findsOneWidget);
    expect(find.text('Start over'), findsOneWidget);
  });

  testWidgets('Disabled scout says so and only offers refresh', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(app(ScoutState.disabled));

    expect(find.text('Scout disabled'), findsOneWidget);
    expect(find.textContaining('disabled by an admin'), findsOneWidget);
    expect(find.text('Refresh'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
