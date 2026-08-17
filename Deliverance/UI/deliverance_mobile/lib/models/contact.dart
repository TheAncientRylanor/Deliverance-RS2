import 'package:json_annotation/json_annotation.dart';

part 'contact.g.dart';

@JsonSerializable()
class Contact {
  final int? id;
  final String? firstName;
  final String? lastName;
  final List<Email>? contactEmails;
  final List<PhoneNumber>? contactPhoneNumbers;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Availability>? availabilities;

  Contact({
    this.id,
    this.firstName,
    this.lastName,
    this.contactEmails,
    this.contactPhoneNumbers,
    this.createdAt,
    this.updatedAt,
    this.availabilities,
  });

  factory Contact.fromJson(Map<String, dynamic> json) =>
      _$ContactFromJson(json);

  Map<String, dynamic> toJson() => _$ContactToJson(this);
}

@JsonSerializable()
class Email {
  final int? id;
  final String? email;

  Email({this.email, this.id});

  factory Email.fromJson(Map<String, dynamic> json) => _$EmailFromJson(json);

  Map<String, dynamic> toJson() => _$EmailToJson(this);
}

@JsonSerializable()
class PhoneNumber {
  final int? id;
  final String? phoneNumber;

  PhoneNumber({this.phoneNumber, this.id});

  factory PhoneNumber.fromJson(Map<String, dynamic> json) =>
      _$PhoneNumberFromJson(json);

  Map<String, dynamic> toJson() => _$PhoneNumberToJson(this);
}

@JsonSerializable()
class Availability {
  final int? id;
  final String? day;
  final String? fromTime;
  final String? toTime;
  final String? pause;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Availability({
    this.id,
    this.day,
    this.fromTime,
    this.toTime,
    this.pause,
    this.createdAt,
    this.updatedAt,
  });

  factory Availability.fromJson(Map<String, dynamic> json) =>
      _$AvailabilityFromJson(json);

  Map<String, dynamic> toJson() => _$AvailabilityToJson(this);
}
