import 'package:flutter/widgets.dart';
import 'package:deliverance_mobile/utils/api_client_exception.dart';
import 'package:deliverance_mobile/utils/form_validators.dart';

class ServerFieldErrors {
  Map<String, String> _errors = {};

  FieldValidator wrap(String field, [FieldValidator? local]) =>
      (value) => local?.call(value) ?? _errors[field.toLowerCase()];

  void clear() => _errors = {};

  void set(String field, String message, GlobalKey<FormState> formKey) {
    _errors = {field.toLowerCase(): message};
    formKey.currentState?.validate();
  }

  bool show(ApiClientException e, GlobalKey<FormState> formKey) {
    if (e.fieldErrors.isEmpty) return false;
    _errors = {
      for (final entry in e.fieldErrors.entries)
        entry.key.toLowerCase(): entry.value,
    };
    formKey.currentState?.validate();
    return true;
  }
}
