enum ScoutTokenStatus {
  pendingApproval(1),
  active(2),
  disabled(3);

  final int value;
  const ScoutTokenStatus(this.value);

  static ScoutTokenStatus fromValue(int value) =>
      ScoutTokenStatus.values.firstWhere((e) => e.value == value);
}

/// Answer to exchanging the scout secret: still waiting for the admin, disabled
/// by an admin, or a short-lived access token.
class ScoutToken {
  final ScoutTokenStatus status;
  final String? accessToken;
  final DateTime? expiresAt;

  ScoutToken({required this.status, this.accessToken, this.expiresAt});

  factory ScoutToken.fromJson(Map<String, dynamic> json) => ScoutToken(
    status: ScoutTokenStatus.fromValue(json['status'] as int),
    accessToken: json['accessToken'] as String?,
    expiresAt: json['expiresAt'] == null
        ? null
        : DateTime.parse(json['expiresAt'] as String),
  );
}
