enum AnswerEnum {
  no(0, 'No'),
  yes(1, 'Yes'),
  notSure(2, 'Not sure');

  final int value;
  final String label;
  const AnswerEnum(this.value, this.label);

  static AnswerEnum fromValue(int value) =>
      AnswerEnum.values.firstWhere((e) => e.value == value);
}
