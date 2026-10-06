class BaseSearchObject {
  int? page;
  int? pageSize;
  bool? includeTotalCount;
  String? sortBy;
  bool? descending;

  BaseSearchObject({
    this.page,
    this.pageSize,
    this.includeTotalCount = true,
    this.sortBy,
    this.descending,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (page != null) map['Page'] = page;
    if (pageSize != null) map['PageSize'] = pageSize;
    if (includeTotalCount != null) map['IncludeTotalCount'] = includeTotalCount;
    if (sortBy != null && sortBy!.isNotEmpty) map['SortBy'] = sortBy;
    if (descending != null) map['Descending'] = descending;
    return map;
  }
}
