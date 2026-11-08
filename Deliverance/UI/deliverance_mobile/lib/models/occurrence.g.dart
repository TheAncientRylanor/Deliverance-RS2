part of 'occurrence.dart';

Occurrence _$OccurrenceFromJson(Map<String, dynamic> json) =>
    Occurrence(id: json['id'] as int?, question: json['question'] as String?);

Map<String, dynamic> _$OccurrenceToJson(Occurrence instance) =>
    <String, dynamic>{'id': instance.id, 'question': instance.question};
