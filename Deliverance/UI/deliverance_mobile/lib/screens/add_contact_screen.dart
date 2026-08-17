import 'package:deliverance_mobile/layouts/master_screen.dart';
import 'package:deliverance_mobile/models/contact.dart';
import 'package:deliverance_mobile/providers/contact_provider.dart';
import 'package:deliverance_mobile/utils/api_client_exception.dart';
import 'package:deliverance_mobile/utils/util_widgets.dart';
import 'package:deliverance_mobile/widgets/custom_buttons.dart';
import 'package:deliverance_mobile/widgets/custom_textController.dart';
import 'package:deliverance_mobile/widgets/custom_text_field.dart';
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

  TextEditingController _firstName = TextEditingController();
  TextEditingController _lastName = TextEditingController();

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
                  text: "${av.day} (${av.fromTime} - ${av.toTime}",
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

      final hourFrom = result.fromTime.hour.toString().padLeft(2, '0');
      final minuteFrom = result.fromTime.minute.toString().padLeft(2, '0');
      final hourTo = result.toTime.hour.toString().padLeft(2, '0');
      final minuteTo = result.toTime.minute.toString().padLeft(2, '0');
      _controllers?[index].text =
          '${result.day} ( $hourFrom:$minuteFrom - $hourTo:$minuteTo )';
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
    setState(() {
      _phoneControllers?.add(CustomTextEditingController());
    });
  }

  void _addNewEmail() {
    setState(() {
      _emailControllers?.add(CustomTextEditingController());
    });
  }

  Future<void> _saveContact() async {
    final contactProvider = context.read<ContactProvider>();
    final Map<String, dynamic> payload = {
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
    };
    if (widget.isUpdating) {
      final updatePayload = {
        'contactEmails':
            _emailControllers
                ?.where((controller) => controller.text.trim().isNotEmpty)
                .map(
                  (controller) => {
                    'id': controller.customKey,
                    'email': controller.text.trim(),
                  },
                )
                .toList() ??
            [],
        'contactPhoneNumbers':
            _phoneControllers
                ?.where((controller) => controller.text.trim().isNotEmpty)
                .map(
                  (controller) => {
                    'id': controller.customKey,
                    'phoneNumber': controller.text.trim(),
                  },
                )
                .toList() ??
            [],
        'availabilities':
            _controllers
                ?.asMap()
                .entries
                .where((entry) => entry.value.text.trim().isNotEmpty)
                .map((entry) {
                  final index = entry.key;
                  return {
                    'id': entry.value.customKey,
                    'day': _selectedDays.elementAt(index),
                    'fromTime': _selectedTimesFrom
                        .elementAt(index)
                        .format(context)
                        .toString()
                        .replaceAll(
                          RegExp(r'\s*(AM|PM)', caseSensitive: false),
                          '',
                        )
                        .trim(),
                    'toTime': _selectedTimesTo
                        .elementAt(index)
                        .format(context)
                        .toString()
                        .replaceAll(
                          RegExp(r'\s*(AM|PM)', caseSensitive: false),
                          '',
                        )
                        .trim(),
                    'pause': null,
                  };
                })
                .toList() ??
            [],
      };
      payload.addAll(updatePayload);
      await contactProvider.update(widget.contact?.id as int, payload);
    } else {
      final insertPayload = {
        'contactEmails':
            _emailControllers
                ?.where((controller) => controller.text.trim().isNotEmpty)
                .map((controller) => {'email': controller.text.trim()})
                .toList() ??
            [],
        'contactPhoneNumbers':
            _phoneControllers
                ?.where((controller) => controller.text.trim().isNotEmpty)
                .map((controller) => {'phoneNumber': controller.text.trim()})
                .toList() ??
            [],
        'availabilities':
            _controllers
                ?.asMap()
                .entries
                .where((entry) => entry.value.text.trim().isNotEmpty)
                .map((entry) {
                  final index = entry.key;
                  return {
                    'day': _selectedDays.elementAt(index),
                    'fromTime': _selectedTimesFrom
                        .elementAt(index)
                        .format(context)
                        .toString()
                        .replaceAll(
                          RegExp(r'\s*(AM|PM)', caseSensitive: false),
                          '',
                        )
                        .trim(),
                    'toTime': _selectedTimesTo
                        .elementAt(index)
                        .format(context)
                        .toString()
                        .replaceAll(
                          RegExp(r'\s*(AM|PM)', caseSensitive: false),
                          '',
                        )
                        .trim(),
                    'pause': null,
                  };
                })
                .toList() ??
            [],
      };
      payload.addAll(insertPayload);
      await contactProvider.insert(payload);
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Add Contact',
      child: Scaffold(
        body: SingleChildScrollView(
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
                      ),
                      const SizedBox(height: 15),
                      CustomTextField(
                        labelText: 'Last name',
                        controller: _lastName,
                      ),
                      DynamicFieldList(
                        labelText: 'Email',
                        controllers: _emailControllers ?? [],
                        addFunction: _addNewEmail,
                      ),
                      DynamicFieldList(
                        labelText: 'Phone number',
                        controllers: _phoneControllers ?? [],
                        addFunction: _addNewPhoneNumber,
                      ),
                      DynamicFieldList(
                        labelText: 'Time available',
                        controllers: _controllers ?? [],
                        addFunction: _addNewField,
                        readOnly: true,
                        onTap: (index) => _displayTimePicker(context, index),
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
                          onPressed: () async {
                            try {
                              await _saveContact();
                            } on ApiClientException catch (e) {
                              alertBox(context, 'Error', e.toString());
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

class ContactAvatarPicker extends StatelessWidget {
  final VoidCallback? onPickPhoto;

  const ContactAvatarPicker({super.key, this.onPickPhoto});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 280,
          width: 280,
          child: Center(
            child: Container(
              width: 240,
              height: 240,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(200),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.0,
                ),
              ),
              child: const Center(
                child: Icon(Icons.person, size: 200.0, color: Colors.white),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          right: 15,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: onPickPhoto ?? () {},
              icon: Icon(
                Icons.camera_alt_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 40,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class LabeledInputWithAddButton extends StatelessWidget {
  final String? labelText;
  final TextEditingController controller;
  final int index;
  final int length;
  final VoidCallback addFunction;
  final VoidCallback? onTap;
  final bool readOnly;

  const LabeledInputWithAddButton({
    super.key,
    this.labelText,
    required this.controller,
    required this.index,
    required this.length,
    required this.addFunction,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLastItem = index == length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CustomTextField(
          labelText: labelText,
          onTap: onTap,
          readOnly: readOnly,
          controller: controller,
        ),
        if (isLastItem)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: _AddFieldButton(onPressed: addFunction),
            ),
          ),
      ],
    );
  }
}

class _AddFieldButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddFieldButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 1.0,
        ),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
    );
  }
}

class DynamicFieldList extends StatelessWidget {
  final String labelText;
  final List<TextEditingController> controllers;
  final VoidCallback addFunction;
  final void Function(int index)? onTap;
  final bool readOnly;

  const DynamicFieldList({
    super.key,
    required this.labelText,
    required this.controllers,
    required this.addFunction,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controllers.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(top: 15),
          child: LabeledInputWithAddButton(
            labelText: labelText,
            controller: controllers[index],
            index: index,
            length: controllers.length,
            addFunction: addFunction,
            onTap: onTap == null ? null : () => onTap!(index),
            readOnly: readOnly,
          ),
        );
      },
    );
  }
}

class AvailabilitySelection {
  final String day;
  final TimeOfDay fromTime;
  final TimeOfDay toTime;

  const AvailabilitySelection({
    required this.day,
    required this.fromTime,
    required this.toTime,
  });
}

const _daysOfWeek = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

Future<AvailabilitySelection?> showAvailabilityDialog(
  BuildContext context, {
  required TimeOfDay initialTime,
  required String initialDay,
}) {
  String selectedDay = initialDay;
  TimeOfDay? pickedTimeFrom;
  TimeOfDay? pickedTimeTo;

  return showDialog<AvailabilitySelection>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickTime({required bool isFrom}) async {
            final picked = await showTimePicker(
              context: context,
              initialTime: initialTime,
              initialEntryMode: TimePickerEntryMode.input,
              builder: (BuildContext context, Widget? child) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(alwaysUse24HourFormat: true),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      timePickerTheme: TimePickerThemeData(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        hourMinuteColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainer,
                        dayPeriodColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainer,
                        dayPeriodTextColor: Theme.of(
                          context,
                        ).colorScheme.onSurface,
                      ),
                    ),
                    child: child!,
                  ),
                );
              },
            );
            if (picked != null) {
              setDialogState(() {
                if (isFrom) {
                  pickedTimeFrom = picked;
                } else {
                  pickedTimeTo = picked;
                }
              });
            }
          }

          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            title: Text('Select availability'),
            titleTextStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day of week',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  spacing: 8,
                  runSpacing: 8,
                  children: _daysOfWeek.map((day) {
                    final isSelected = selectedDay == day;
                    return ChoiceChip(
                      label: Text(day),
                      selected: isSelected,
                      selectedColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      onSelected: (_) {
                        setDialogState(() {
                          selectedDay = day;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Time from',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainer,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => pickTime(isFrom: true),
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      pickedTimeFrom?.format(context) ??
                          initialTime.format(context),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Time to',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainer,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => pickTime(isFrom: false),
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      pickedTimeTo?.format(context) ??
                          initialTime.format(context),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (pickedTimeFrom != null && pickedTimeTo != null) {
                    Navigator.pop(
                      dialogContext,
                      AvailabilitySelection(
                        day: selectedDay,
                        fromTime: pickedTimeFrom!,
                        toTime: pickedTimeTo!,
                      ),
                    );
                  } else {
                    Navigator.pop(dialogContext);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}
