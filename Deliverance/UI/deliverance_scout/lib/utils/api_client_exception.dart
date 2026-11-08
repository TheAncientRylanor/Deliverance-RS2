import 'dart:convert';

class ApiClientException implements Exception {
  ApiClientException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiErrorParser {
  ApiErrorParser._();

  static String? messageFromBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);

      final root = map['message'];
      final rootMessages = _messagesFromValue(root);
      if (rootMessages.isNotEmpty) {
        return rootMessages.toSet().join('\n');
      }

      final errors = map['errors'];
      if (errors is Map) {
        final errMap = Map<String, dynamic>.from(errors);
        final parts = <String>[];

        void addKey(String key) {
          parts.addAll(_messagesFromValue(errMap[key]));
        }

        addKey('clientError');
        for (final key in errMap.keys) {
          if (key == 'clientError') continue;
          addKey(key);
        }

        final unique = parts.toSet().toList();
        if (unique.isNotEmpty) return unique.join('\n');
      } else if (errors is List) {
        final parts = _messagesFromValue(errors);
        if (parts.isNotEmpty) return parts.toSet().join('\n');
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static List<String> _messagesFromValue(dynamic v) {
    if (v is List) {
      final out = <String>[];
      for (final e in v) {
        if (e is String) {
          final s = e.trim();
          if (s.isNotEmpty) out.add(s);
        } else if (e is Map) {
          final m = e['message'] ?? e['msg'] ?? e['error'];
          if (m is String && m.trim().isNotEmpty) {
            out.add(m.trim());
          }
        }
      }
      return out;
    }
    if (v is String) {
      final s = v.trim();
      return s.isEmpty ? [] : [s];
    }
    return [];
  }
}
