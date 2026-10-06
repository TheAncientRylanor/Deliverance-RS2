enum ReportStatusFilter {
  active(1, 'Active'),
  cleared(2, 'Cleared'),
  draft(3, 'Drafts');

  final int value;
  final String label;
  const ReportStatusFilter(this.value, this.label);

  static ReportStatusFilter fromValue(int value) =>
      ReportStatusFilter.values.firstWhere((e) => e.value == value);
}
