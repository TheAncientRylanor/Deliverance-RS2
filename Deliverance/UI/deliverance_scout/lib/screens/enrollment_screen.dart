import 'package:deliverance_scout/providers/scout_auth_provider.dart';
import 'package:deliverance_scout/providers/scout_enrollment_provider.dart';
import 'package:deliverance_scout/utils/device_info_collector.dart';
import 'package:deliverance_scout/widgets/custom_buttons.dart';
import 'package:deliverance_scout/widgets/custom_text_field.dart';
import 'package:deliverance_scout/widgets/scout_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EnrollmentScreen extends StatefulWidget {
  const EnrollmentScreen({super.key});

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  final _tokenController = TextEditingController();
  bool _isEnrolling = false;
  String? _error;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _enroll() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(
        () => _error = "Paste the enrollment token from the admin app first.",
      );
      return;
    }

    final enrollmentProvider = context.read<ScoutEnrollmentProvider>();
    final authProvider = context.read<ScoutAuthProvider>();
    setState(() {
      _isEnrolling = true;
      _error = null;
    });
    try {
      final deviceInfo = await DeviceInfoCollector().collect();
      final secret = await enrollmentProvider.claim(token, deviceInfo);
      // Switches the app to the "waiting for approval" screen.
      await authProvider.onEnrolled(secret);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isEnrolling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // E.g. why the scout was sent back here (enrollment cancelled).
    final message = _error ?? context.watch<ScoutAuthProvider>().message;
    return ScoutPage(
      message: message,
      isError: true,
      children: [
        CustomTextField(
          controller: _tokenController,
          labelText: "Enrollment token",
        ),
        PrimaryButton(
          onPressed: _enroll,
          isLoading: _isEnrolling,
          label: "Enroll",
        ),
      ],
    );
  }
}
