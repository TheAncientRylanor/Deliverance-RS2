import 'package:deliverance_mobile/models/contact.dart';
import 'package:deliverance_mobile/providers/base_provider.dart';

class ContactProvider extends BaseProvider<Contact> {
  ContactProvider() : super("Contacts");
  @override
  Contact fromJson(data) {
    return Contact.fromJson(data);
  }
}
