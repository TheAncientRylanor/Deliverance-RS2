part of 'occurance.dart';

Occurance _$OccuranceFromJson(Map<String, dynamic> json) => Occurance(
  id: json['id'] as int?,
  question: json['question'] as String?,
);

Map<String, dynamic> _$OccuranceToJson(Occurance instance) =>
    <String, dynamic>{'id': instance.id, 'question': instance.question};
