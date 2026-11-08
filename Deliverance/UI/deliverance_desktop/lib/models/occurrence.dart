import 'package:json_annotation/json_annotation.dart';

part 'occurrence.g.dart';

@JsonSerializable()
class Occurrence {
  final int? id;
  final String? question;

  Occurrence({this.id, this.question});

  factory Occurrence.fromJson(Map<String, dynamic> json) =>
      _$OccurrenceFromJson(json);

  Map<String, dynamic> toJson() => _$OccurrenceToJson(this);
}
