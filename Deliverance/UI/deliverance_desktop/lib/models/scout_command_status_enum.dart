enum ScoutCommandStatusEnum {
  pending(1, 'Pending'),
  running(2, 'Running'),
  completed(3, 'Completed'),
  failed(4, 'Failed'),
  timedOut(5, 'Timed out');

  final int value;
  final String label;
  const ScoutCommandStatusEnum(this.value, this.label);

  static ScoutCommandStatusEnum fromValue(int value) =>
      ScoutCommandStatusEnum.values.firstWhere((e) => e.value == value);

  bool get isFinished => this != pending && this != running;
}
