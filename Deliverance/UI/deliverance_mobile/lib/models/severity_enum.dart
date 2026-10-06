enum SeverityEnum {
  none(1, 'None'),
  mild(2, 'Mild'),
  medium(3, 'Medium'),
  danger(4, 'Danger'),
  extreme(5, 'Extreme');

  final int value;
  final String label;
  const SeverityEnum(this.value, this.label);

  static SeverityEnum fromValue(int value) =>
      SeverityEnum.values.firstWhere((e) => e.value == value);
}
