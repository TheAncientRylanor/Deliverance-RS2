import 'package:deliverance_mobile/layouts/master_screen.dart';
import 'package:deliverance_mobile/models/contact.dart';
import 'package:deliverance_mobile/models/search_result.dart';
import 'package:deliverance_mobile/providers/contact_provider.dart';
import 'package:deliverance_mobile/screens/add_contact_screen.dart';
import 'package:deliverance_mobile/utils/util_widgets.dart';
import 'package:deliverance_mobile/widgets/custom_buttons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});
  @override
  State<ContactsScreen> createState() => _ContactsScreen();
}

class _ContactsScreen extends State<ContactsScreen> {
  late ContactProvider _contactProvider;
  late SearchResult<Contact> _contacts;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _contactProvider = context.read<ContactProvider>();
    _initValues();
  }

  Future<void> _initValues() async {
    try {
      final data = await _contactProvider.get();
      setState(() {
        _contacts = data;
        isLoading = false;
      });
    } on Exception catch (e) {
      if (mounted) alertBox(context, 'Error', e.toString());
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleRemove(Contact contact) async {
    final confirmed = await showDeleteContactDialog(context);
    if (confirmed != true) return;
    if (!mounted) return;

    try {
      _contactProvider.remove(contact.id as int);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contact sucessfuly removed")),
      );
      setState(() => isLoading = true);
      await _initValues();
    } on Exception catch (e) {
      if (mounted) alertBox(context, 'Error', e.toString());
    }
  }

  Future<void> _handleEdit(Contact contact) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddContactScreen(isUpdating: true, contact: contact),
      ),
    );

    if (result == true) {
      setState(() {
        isLoading = true;
        _initValues();
      });
    }
  }

  Future<void> _handleAddContact() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddContactScreen(isUpdating: false),
      ),
    );

    if (result == true) {
      setState(() {
        isLoading = true;
        _initValues();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: "Contacts",
      child: Scaffold(
        body: isLoading
            ? Center(
                child: globalLoadingSpinner(
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : SingleChildScrollView(
                child: Center(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 70.0),
                        child: Text(
                          "Contacts",
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                      ),
                      PrimaryButton(
                        onPressed: _handleAddContact,
                        label: "Add contact",
                        width: 180,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 50,
                        ),
                        child: ContactList(
                          contacts: _contacts.items ?? [],
                          onEdit: _handleEdit,
                          onRemove: _handleRemove,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class ContactList extends StatelessWidget {
  final List<Contact> contacts;
  final void Function(Contact contact) onEdit;
  final void Function(Contact contact) onRemove;

  const ContactList({
    super.key,
    required this.contacts,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final contact in contacts)
          ContactCard(
            contact: contact,
            onEdit: () => onEdit(contact),
            onRemove: () => onRemove(contact),
          ),
      ],
    );
  }
}
/*
return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
   
      },
    );
*/

class ContactCard extends StatelessWidget {
  final Contact contact;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const ContactCard({
    super.key,
    required this.contact,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Card(
        clipBehavior: Clip.hardEdge,
        elevation: 10,
        shadowColor: Colors.black,
        color: Theme.of(context).colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
          side: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        child: InkWell(
          onTap: () {
            showContactDialog(context, contact);
          },
          child: SizedBox(
            width: double.infinity,
            height: 320,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 5,
                  children: [
                    const _ContactAvatar(),
                    Text(
                      '${contact.firstName} ${contact.lastName}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Text(
                      contact.contactPhoneNumbers
                              ?.elementAtOrNull(0)
                              ?.phoneNumber ??
                          "",
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      contact.contactEmails?.elementAtOrNull(0)?.email ?? "",
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        spacing: 20,
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              onPressed: onRemove,
                              label: "Remove",
                              height: 30,
                            ),
                          ),
                          Expanded(
                            child: PrimaryButton(
                              onPressed: onEdit,
                              label: "Edit",
                              height: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactAvatar extends StatelessWidget {
  const _ContactAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(200),
        border: Border.all(color: Theme.of(context).colorScheme.primary),
      ),
      child: const Icon(Icons.person, size: 80.0, color: Colors.white),
    );
  }
}

class _ContactEmailList extends StatelessWidget {
  final List<Email> emails;

  const _ContactEmailList({required this.emails});

  @override
  Widget build(BuildContext context) {
    if (emails.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final email in emails)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.0,
                ),
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                email.email as String,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
      ],
    );
  }
}

class _ContactPhoneList extends StatelessWidget {
  final List<PhoneNumber> phoneNumbers;

  const _ContactPhoneList({required this.phoneNumbers});

  @override
  Widget build(BuildContext context) {
    if (phoneNumbers.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final phone in phoneNumbers)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.0,
                ),
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                phone.phoneNumber as String,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
      ],
    );
  }
}

class _ContactAvailabilty extends StatelessWidget {
  final List<Availability> availability;

  const _ContactAvailabilty({required this.availability});

  @override
  Widget build(BuildContext context) {
    if (availability.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final ava in availability)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Text(
                      ava.day as String,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    '${ava.fromTime ?? ''} - ${ava.toTime ?? ''}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

void showContactDialog(BuildContext context, Contact contact) {
  final emails = contact.contactEmails ?? [];
  final phoneNumbers = contact.contactPhoneNumbers ?? [];
  final availability = contact.availabilities ?? [];
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      title: Center(child: Text('${contact.firstName} ${contact.lastName}')),
      titleTextStyle: Theme.of(context).textTheme.headlineMedium,
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Emails", style: Theme.of(context).textTheme.headlineSmall),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SizedBox(
              width: double.maxFinite,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _ContactEmailList(emails: emails),
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            "Phone numbers",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SizedBox(
              width: double.maxFinite,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _ContactPhoneList(phoneNumbers: phoneNumbers),
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            "Availability",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SizedBox(
              width: double.maxFinite,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _ContactAvailabilty(availability: availability),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<bool?> showDeleteContactDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      title: Center(
        child: Text(
          "Delete",
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight(1000)),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Are you sure you want to delete this contact',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
      actions: [
        Row(
          spacing: 20,
          children: [
            Expanded(
              child: SecondaryButton(
                onPressed: () => Navigator.pop(context, false),
                label: "Cancel",
              ),
            ),
            Expanded(
              child: PrimaryButton(
                onPressed: () => Navigator.pop(context, true),
                label: "Yes",
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
