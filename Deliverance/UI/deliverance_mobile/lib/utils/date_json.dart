DateTime dateFromJson(String value) => DateTime.parse(value).toLocal();

DateTime? nullableDateFromJson(String? value) =>
    value == null ? null : dateFromJson(value);

String dateToJson(DateTime value) => value.toUtc().toIso8601String();

String? nullableDateToJson(DateTime? value) =>
    value == null ? null : dateToJson(value);
