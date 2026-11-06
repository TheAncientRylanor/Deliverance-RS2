enum ExecutionCommandEnum {
  cmd(1, 'CMD'),
  powerShell(2, 'PowerShell');

  final int value;
  final String label;
  const ExecutionCommandEnum(this.value, this.label);

  static ExecutionCommandEnum fromValue(int value) =>
      ExecutionCommandEnum.values.firstWhere((e) => e.value == value);
}
