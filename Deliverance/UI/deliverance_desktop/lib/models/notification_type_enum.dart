enum NotificationTypeEnum {
  reportSent(1),
  reportSeen(2),
  reportCleared(3),
  userRegistered(4);

  final int value;
  const NotificationTypeEnum(this.value);

  static NotificationTypeEnum fromValue(int value) =>
      NotificationTypeEnum.values.firstWhere((e) => e.value == value);
}
