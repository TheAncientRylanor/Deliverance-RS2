import 'package:deliverance_desktop/models/scout_enrollment.dart';
import 'package:deliverance_desktop/providers/scout_enrollment_provider.dart';
import 'package:deliverance_desktop/utils/enrollment_hub_client.dart';
import 'package:deliverance_desktop/widgets/custom_buttons.dart';
import 'package:deliverance_desktop/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// "Generate enrollment token" part of the device dialog: creates the token,
/// shows it for copying, and listens over SignalR until the scout claims it.
class ScoutEnrollmentSection extends StatefulWidget {
  final bool enabled;
  final void Function(ScoutEnrollment enrollment) onClaimed;
  final VoidCallback? onTokenGenerated;

  const ScoutEnrollmentSection({
    super.key,
    required this.onClaimed,
    this.onTokenGenerated,
    this.enabled = true,
  });

  @override
  State<ScoutEnrollmentSection> createState() => _ScoutEnrollmentSectionState();
}

class _ScoutEnrollmentSectionState extends State<ScoutEnrollmentSection> {
  final _tokenController = TextEditingController();
  EnrollmentHubClient? _hubClient;
  ScoutEnrollmentToken? _token;
  ScoutEnrollment? _claimed;
  bool _isGenerating = false;
  String? _error;

  @override
  void dispose() {
    _hubClient?.stop();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final provider = context.read<ScoutEnrollmentProvider>();
    final previous = _token;
    setState(() {
      _isGenerating = true;
      _error = null;
    });
    try {
      await _hubClient?.stop();
      _hubClient = null;
      if (previous != null && _claimed == null) {
        // The old token is replaced, so it shouldn't be claimable any more.
        provider.cancel(previous.enrollmentId).ignore();
      }

      final token = await provider.generateToken();
      if (!mounted) return;
      setState(() {
        _token = token;
        _claimed = null;
        _tokenController.text = token.token;
      });
      widget.onTokenGenerated?.call();

      final hubClient = EnrollmentHubClient(
        enrollmentId: token.enrollmentId,
        onClaimed: _handleClaimed,
      );
      _hubClient = hubClient;
      await hubClient.start();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _handleClaimed(ScoutEnrollment enrollment) {
    if (!mounted) return;
    setState(() => _claimed = enrollment);
    widget.onClaimed(enrollment);
    // Nothing more will arrive for this enrollment.
    _hubClient?.stop();
    _hubClient = null;
  }

  Future<void> _copyToken() async {
    await Clipboard.setData(ClipboardData(text: _tokenController.text));
  }

  String? get _statusText {
    if (_error != null) return _error;
    final claimed = _claimed;
    if (claimed != null) {
      final name = claimed.hostname == null
          ? "Scout"
          : "Scout ${claimed.hostname}";
      return "$name connected. Its details were filled in below.";
    }
    final token = _token;
    if (token != null) {
      final expires = DateFormat.Hm().format(token.expiresAt.toLocal());
      return "Paste the token into the scout app. "
          "Waiting for the scout... (expires at $expires)";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusText;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        PrimaryButton(
          onPressed: widget.enabled && _claimed == null ? _generate : null,
          isLoading: _isGenerating,
          label: "Generate enrollment token",
          width: 250,
        ),
        CustomTextField(
          controller: _tokenController,
          readOnly: true,
          width: 300,
          suffixIcon: IconButton(
            tooltip: "Copy token",
            onPressed: _token == null ? null : _copyToken,
            icon: const Icon(Icons.copy, size: 18),
          ),
        ),
        if (status != null)
          Text(
            status,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _error != null
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white70,
            ),
          ),
      ],
    );
  }
}
