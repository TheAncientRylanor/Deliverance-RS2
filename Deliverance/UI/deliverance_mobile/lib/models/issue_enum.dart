enum IssueEnum {
  hardware(1, 'Hardware'),
  software(2, 'Software'),
  both(3, 'Both');

  final int value;
  final String label;
  const IssueEnum(this.value, this.label);

  static IssueEnum fromValue(int value) =>
      IssueEnum.values.firstWhere((e) => e.value == value);
}
