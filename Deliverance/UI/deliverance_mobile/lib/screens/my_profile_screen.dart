import 'dart:io';

import 'package:deliverance_mobile/layouts/master_screen.dart';
import 'package:deliverance_mobile/models/user.dart';
import 'package:deliverance_mobile/models/user.multipart.dart';
import 'package:deliverance_mobile/models/user.update.multipart.dart';
import 'package:deliverance_mobile/providers/auth_provider.dart';
import 'package:deliverance_mobile/providers/user_provider.dart';
import 'package:deliverance_mobile/utils/api_client_exception.dart';
import 'package:deliverance_mobile/utils/util_widgets.dart';
import 'package:deliverance_mobile/widgets/custom_buttons.dart';
import 'package:deliverance_mobile/widgets/custom_text_field.dart';
import 'package:deliverance_mobile/widgets/image_holder.dart';
import 'package:deliverance_mobile/widgets/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});
  @override
  State<MyProfileScreen> createState() => _MyProfileScreen();
}

class _MyProfileScreen extends State<MyProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late AuthProvider _authProvider;
  late UserProvider _userProvider;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;
  User? result;
  bool isReadOnly = true;
  final _baseUrl = const String.fromEnvironment(
    "baseUrl",
    defaultValue: "http://10.0.2.2:5095/",
  );
  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
    _userProvider = context.read<UserProvider>();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    initValues();
  }

  void initValues() {
    _usernameController.text = _userProvider.data?.username as String;
    _emailController.text = _userProvider.data?.email as String;
    _lastNameController.text = _userProvider.data?.lastName ?? "";
    _firstNameController.text = _userProvider.data?.firstName ?? "";
  }

  void toggleEdit() {
    setState(() {
      isReadOnly = !isReadOnly;
    });
  }

  String get editButtonText => isReadOnly ? "Edit" : "Save";
  Future<void> onEditButtonPressed() async {
    if (isReadOnly) {
      toggleEdit(); // just enter edit mode
    } else {
      await saveValues(); // currently editing -> attempt save
    }
  }

  Future saveValues() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        final newRequest = UserUpdateMultipart(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          username: _usernameController.text,
          profileImage: _selectedImage,
        );
        await _userProvider.updateUser(
          _userProvider.data!.uuid as String,
          newRequest,
        );
        setState(() => isReadOnly = true);
      } on ApiClientException catch (e) {
        alertBox(context, "Update error", e.message);
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: "My profile",
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
                      Stack(
                        children: [
                          SizedBox(
                            height: 280,
                            width: 280,
                            child: Align(
                              alignment: Alignment.center,
                              child: Container(
                                width: 240,
                                height: 240,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(200),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    width: 1.0,
                                  ),
                                ),
                                child: Center(
                                  child: ClipOval(
                                    child: buildProfileImage(
                                      _selectedImage,
                                      _userProvider.data?.imagePath ?? "",
                                      _baseUrl,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          if (!isReadOnly)
                            Positioned(
                              bottom: 5,
                              right: 15,
                              child: Container(
                                width: 80,
                                height: 80,

                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainer,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    width: 1.5,
                                  ),
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () async {
                                    final tempImage = await pickImage(
                                      ImageSource.gallery,
                                      _picker,
                                    );
                                    if (!mounted) return;
                                    if (tempImage != null) {
                                      setState(() {
                                        _selectedImage = tempImage;
                                      });
                                    }
                                  },
                                  icon: Icon(
                                    Icons.camera_alt_outlined,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 40),
                      Form(
                        key: _formKey,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            spacing: 15,
                            children: [
                              CustomTextField(
                                controller: _firstNameController,
                                labelText: "First name",
                                readOnly: isReadOnly,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your first name';
                                  }
                                  return null;
                                },
                              ),
                              CustomTextField(
                                controller: _lastNameController,
                                labelText: "Last name",
                                readOnly: isReadOnly,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your last name';
                                  }
                                  return null;
                                },
                              ),
                              CustomTextField(
                                controller: _usernameController,
                                labelText: "Username",
                                readOnly: isReadOnly,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your username';
                                  }
                                  return null;
                                },
                              ),
                              CustomTextField(
                                controller: _emailController,
                                labelText: "Email",
                                readOnly: isReadOnly,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null; // Return null when validation passes
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 60,
                          horizontal: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: SecondaryButton(
                                onPressed: () async {
                                  final result = await alertBox(
                                    context,
                                    "Are you sure that you want to log out?",
                                    "Confirmation",
                                  );
                                  if (result == true) {
                                    try {
                                      await _authProvider.logout();
                                      if (!context.mounted) return;
                                      Navigator.popUntil(
                                        context,
                                        (route) => route.isFirst,
                                      );
                                    } on ApiClientException catch (e) {
                                      if (!context.mounted) return;
                                      Navigator.pop(context);
                                      alertBox(context, "Error", e.toString());
                                    }
                                  }
                                },
                                label: "Log out",
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PrimaryButton(
                                onPressed: () {
                                  onEditButtonPressed();
                                },
                                label: editButtonText,
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

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
