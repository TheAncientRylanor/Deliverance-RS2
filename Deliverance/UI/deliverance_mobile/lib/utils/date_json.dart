// The API stores and sends every time as UTC (ending in "Z"). Models turn them into
// local time when reading, so screens can show them as they are, and back into UTC
// when sending, so the API always receives the same zone.

DateTime dateFromJson(String value) => DateTime.parse(value).toLocal();

DateTime? nullableDateFromJson(String? value) =>
    value == null ? null : dateFromJson(value);

String dateToJson(DateTime value) => value.toUtc().toIso8601String();

String? nullableDateToJson(DateTime? value) =>
    value == null ? null : dateToJson(value);
