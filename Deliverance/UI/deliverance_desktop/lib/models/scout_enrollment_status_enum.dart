enum ScoutEnrollmentStatusEnum {
  pending(1, 'Pending'),
  claimed(2, 'Claimed'),
  completed(3, 'Completed'),
  cancelled(4, 'Cancelled');

  final int value;
  final String label;
  const ScoutEnrollmentStatusEnum(this.value, this.label);

  static ScoutEnrollmentStatusEnum fromValue(int value) =>
      ScoutEnrollmentStatusEnum.values.firstWhere((e) => e.value == value);
}
