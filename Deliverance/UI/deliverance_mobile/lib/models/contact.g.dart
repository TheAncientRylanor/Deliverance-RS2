part of 'contact.dart';

Contact _$ContactFromJson(Map<String, dynamic> json) => Contact(
  id: json['id'] as int?,
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
  contactEmails: (json['contactEmails'] as List<dynamic>?)
      ?.map((e) => Email.fromJson(e as Map<String, dynamic>))
      .toList(),
  contactPhoneNumbers: (json['contactPhoneNumbers'] as List<dynamic>?)
      ?.map((e) => PhoneNumber.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  availabilities: (json['availabilities'] as List<dynamic>?)
      ?.map((e) => Availability.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ContactToJson(Contact instance) => <String, dynamic>{
  'id': instance.id,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'contactEmails': instance.contactEmails?.map((e) => e.toJson()).toList(),
  'contactPhoneNumbers': instance.contactPhoneNumbers
      ?.map((e) => e.toJson())
      .toList(),
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'availabilities': instance.availabilities?.map((e) => e.toJson()).toList(),
};

Email _$EmailFromJson(Map<String, dynamic> json) =>
    Email(email: json['email'] as String?, id: json['id'] as int?);

Map<String, dynamic> _$EmailToJson(Email instance) => <String, dynamic>{
  'email': instance.email,
  'id': instance.id,
};

PhoneNumber _$PhoneNumberFromJson(Map<String, dynamic> json) => PhoneNumber(
  phoneNumber: json['phoneNumber'] as String?,
  id: json['id'] as int?,
);

Map<String, dynamic> _$PhoneNumberToJson(PhoneNumber instance) =>
    <String, dynamic>{'phoneNumber': instance.phoneNumber, 'id': instance.id};

Availability _$AvailabilityFromJson(Map<String, dynamic> json) => Availability(
  id: json['id'] as int?,
  day: json['day'] as String?,
  fromTime: json['fromTime'] as String?,
  toTime: json['toTime'] as String?,
  pause: json['pause'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$AvailabilityToJson(Availability instance) =>
    <String, dynamic>{
      'id': instance.id,
      'day': instance.day,
      'fromTime': instance.fromTime,
      'toTime': instance.toTime,
      'pause': instance.pause,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
