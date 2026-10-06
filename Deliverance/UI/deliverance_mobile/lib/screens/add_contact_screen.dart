import 'package:deliverance_mobile/models/contact.dart';
import 'package:deliverance_mobile/providers/contact_provider.dart';
import 'package:deliverance_mobile/utils/api_client_exception.dart';
import 'package:deliverance_mobile/utils/util_widgets.dart';
import 'package:deliverance_mobile/widgets/dialogs/availability_dialog.dart';
import 'package:deliverance_mobile/widgets/contact_avatar_picker.dart';
import 'package:deliverance_mobile/widgets/custom_buttons.dart';
import 'package:deliverance_mobile/widgets/custom_textController.dart';
import 'package:deliverance_mobile/widgets/custom_text_field.dart';
import 'package:deliverance_mobile/widgets/custom_toast.dart';
import 'package:deliverance_mobile/widgets/dynamic_field_list.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

class AddContactScreen extends StatefulWidget {
  final bool isUpdating;
  final Contact? contact;
  const AddContactScreen({super.key, required this.isUpdating, this.contact});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  List<CustomTextEditingController>? _controllers = [];
  List<CustomTextEditingController>? _phoneControllers = [];
  List<CustomTextEditingController>? _emailControllers = [];
  List<TimeOfDay> _selectedTimesFrom = [];
  List<TimeOfDay> _selectedTimesTo = [];
  List<String> _selectedDays = [];
  final _contactKey = GlobalKey<FormState>();
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Add an initial text field on load
    if (widget.isUpdating) {
      setUpdate();
    } else {
      _addNewField();
      _addNewEmail();
      _addNewPhoneNumber();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers ?? []) {
      controller.dispose();
    }
    for (final controller in _phoneControllers ?? []) {
      controller.dispose();
    }
    for (final controller in _emailControllers ?? []) {
      controller.dispose();
    }
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  void setUpdate() {
    setState(() {
      _phoneControllers =
          widget.contact?.contactPhoneNumbers
              ?.map(
                (phn) => CustomTextEditingController(
                  text: phn.phoneNumber,
                  customKey: phn.id,
                ),
              )
              .toList() ??
          [];
      _emailControllers =
          widget.contact?.contactEmails
              ?.map(
                (em) => CustomTextEditingController(
                  text: em.email,
                  customKey: em.id,
                ),
              )
              .toList() ??
          [];
      _firstName.text = widget.contact?.firstName ?? "";
      _lastName.text = widget.contact?.lastName ?? "";
      _selectedDays =
          widget.contact?.availabilities?.map((av) => av.day ?? "").toList() ??
          [];
      _selectedTimesFrom =
          widget.contact?.availabilities
              ?.map((av) => stringToTimeOfDay(av.fromTime ?? ""))
              .toList() ??
          [];
      _selectedTimesTo =
          widget.contact?.availabilities
              ?.map((av) => stringToTimeOfDay(av.toTime ?? ""))
              .toList() ??
          [];
      _controllers =
          widget.contact?.availabilities
              ?.map(
                (av) => CustomTextEditingController(
                  text: _formatAvailabilityText(
                    av.day ?? "",
                    stringToTimeOfDay(av.fromTime ?? ""),
                    stringToTimeOfDay(av.toTime ?? ""),
                  ),
                  customKey: av.id,
                ),
              )
              .toList() ??
          [];
    });
  }

  TimeOfDay stringToTimeOfDay(String timeString) {
    List<String> parts = timeString.split(':');

    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatAvailabilityText(String day, TimeOfDay from, TimeOfDay to) {
    final hourFrom = from.hour.toString().padLeft(2, '0');
    final minuteFrom = from.minute.toString().padLeft(2, '0');
    final hourTo = to.hour.toString().padLeft(2, '0');
    final minuteTo = to.minute.toString().padLeft(2, '0');
    return '$day ( $hourFrom:$minuteFrom - $hourTo:$minuteTo )';
  }

  Future<void> _displayTimePicker(BuildContext context, int index) async {
    if (index < 0 || index >= _controllers!.length) return;

    final TimeOfDay initialTime = index < _selectedTimesFrom.length
        ? _selectedTimesFrom[index]
        : TimeOfDay.now();
    final String initialDay = index < _selectedDays.length
        ? _selectedDays[index]
        : 'Monday';

    final result = await showAvailabilityDialog(
      context,
      initialTime: initialTime,
      initialDay: initialDay,
    );
    if (result == null || !mounted) return;

    setState(() {
      _selectedDays[index] = result.day;
      _selectedTimesFrom[index] = result.fromTime;
      _selectedTimesTo[index] = result.toTime;

      _controllers?[index].text = _formatAvailabilityText(
        result.day,
        result.fromTime,
        result.toTime,
      );
    });
  }

  void _addNewField() {
    setState(() {
      _controllers?.add(CustomTextEditingController());
      _selectedTimesFrom.add(TimeOfDay.now());
      _selectedTimesTo.add(TimeOfDay.now());
      _selectedDays.add('Monday');
    });
  }

  void _addNewPhoneNumber() {
    if (_phoneControllers!.length == 10) return;
    setState(() {
      _phoneControllers?.add(CustomTextEditingController());
    });
  }

  void _addNewEmail() {
    if (_emailControllers!.length == 10) return;
    setState(() {
      _emailControllers?.add(CustomTextEditingController());
    });
  }

  void _removeEmail(int index) {
    if (index == 0) return;
    setState(() {
      _emailControllers?.removeAt(index);
    });
  }

  void _removePhone(int index) {
    if (index == 0) return;
    setState(() {
      _phoneControllers?.removeAt(index);
    });
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return time
        .format(context)
        .toString()
        .replaceAll(RegExp(r'\s*(AM|PM)', caseSensitive: false), '')
        .trim();
  }

  Future<void> _saveContact() async {
    final contactProvider = context.read<ContactProvider>();

    final emails = (_emailControllers ?? [])
        .where((controller) => controller.text.trim().isNotEmpty)
        .map(
          (controller) =>
              Email(id: controller.customKey, email: controller.text.trim()),
        )
        .toList();

    final phoneNumbers = (_phoneControllers ?? [])
        .where((controller) => controller.text.trim().isNotEmpty)
        .map(
          (controller) => PhoneNumber(
            id: controller.customKey,
            phoneNumber: controller.text.trim(),
          ),
        )
        .toList();

    final availabilities = (_controllers ?? [])
        .asMap()
        .entries
        .where((entry) => entry.value.text.trim().isNotEmpty)
        .map((entry) {
          final index = entry.key;
          return Availability(
            id: entry.value.customKey,
            day: _selectedDays.elementAt(index),
            fromTime: _formatTimeOfDay(_selectedTimesFrom.elementAt(index)),
            toTime: _formatTimeOfDay(_selectedTimesTo.elementAt(index)),
          );
        })
        .toList();

    final contact = Contact(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      contactEmails: emails,
      contactPhoneNumbers: phoneNumbers,
      availabilities: availabilities,
    );

    if (widget.isUpdating) {
      await contactProvider.update(widget.contact?.id as int, contact.toJson());
    } else {
      await contactProvider.insert(contact.toJson());
    }
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _contactKey,
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 70.0),
                  child: Text(
                    "Add contact",
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ),
                const ContactAvatarPicker(),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      CustomTextField(
                        labelText: 'First name',
                        controller: _firstName,
                        validator: (value) {
                          if (value == null || value == "") {
                            return "First name is empty";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      CustomTextField(
                        labelText: 'Last name',
                        controller: _lastName,
                        validator: (value) {
                          if (value == null || value == "") {
                            return "Last name is empty";
                          }
                          return null;
                        },
                      ),
                      DynamicFieldList(
                        labelText: 'Email',
                        controllers: _emailControllers ?? [],
                        addFunction: _addNewEmail,
                        removeFunction: _removeEmail,
                        hasValidator: true,
                      ),
                      DynamicFieldList(
                        labelText: 'Phone number',
                        controllers: _phoneControllers ?? [],
                        addFunction: _addNewPhoneNumber,
                        removeFunction: _removePhone,
                        hasValidator: true,
                      ),
                      DynamicFieldList(
                        labelText: 'Time available',
                        controllers: _controllers ?? [],
                        addFunction: _addNewField,
                        readOnly: true,
                        onTap: (index) => _displayTimePicker(context, index),
                        hasValidator: false,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 60,
                    horizontal: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          onPressed: () => Navigator.pop(context),
                          label: "Cancel",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          isLoading: _isSaving,
                          onPressed: () async {
                            if (_contactKey.currentState!.validate() ||
                                _phoneControllers!.isEmpty ||
                                _emailControllers!.isEmpty) {
                              setState(() => _isSaving = true);
                              try {
                                await _saveContact();
                                if (!mounted) return;
                                showCustomToast(
                                  context,
                                  "Contact successfully saved ",
                                );
                                await Future.delayed(
                                  const Duration(milliseconds: 200),
                                );
                                if (!context.mounted) return;
                                Navigator.pop(context, true);
                              } on ApiClientException catch (e) {
                                if (!mounted) return;
                                // ignore: use_build_context_synchronously
                                alertBox(context, 'Error', e.toString());
                              } finally {
                                if (mounted) setState(() => _isSaving = false);
                              }
                            }
                          },
                          label: 'Save',
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
    );
  }
}
