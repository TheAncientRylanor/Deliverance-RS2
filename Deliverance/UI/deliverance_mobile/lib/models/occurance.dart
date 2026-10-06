import 'package:json_annotation/json_annotation.dart';

part 'occurance.g.dart';

@JsonSerializable()
class Occurance {
  final int? id;
  final String? question;

  Occurance({this.id, this.question});

  factory Occurance.fromJson(Map<String, dynamic> json) =>
      _$OccuranceFromJson(json);

  Map<String, dynamic> toJson() => _$OccuranceToJson(this);
}
