/// One line sent to POST Scout/Logs. [count] is how many events were merged
/// into it, and [eventKey] lets the server skip a line it already saved.
class ScoutLogEntry {
  final String eventKey;
  final DateTime dateLogged;
  final String source;
  final int eventId;
  final int count;
  final String message;

  ScoutLogEntry({
    required this.eventKey,
    required this.dateLogged,
    required this.source,
    required this.eventId,
    required this.message,
    this.count = 1,
  });

  Map<String, dynamic> toJson() => {
    'eventKey': eventKey,
    'dateLogged': dateLogged.toUtc().toIso8601String(),
    'source': source,
    'eventId': eventId,
    'count': count,
    'message': message,
  };
}
