enum ReportStateEnum {
  seen(0, 'SeenReportState'),
  unseen(1, 'UnseenReportState'),
  cleared(2, 'ClearedReportState'),
  draft(3, 'DraftReportState');

  final int value;
  final String label;
  const ReportStateEnum(this.value, this.label);

  static ReportStateEnum fromValue(int value) =>
      ReportStateEnum.values.firstWhere((e) => e.value == value);
}
