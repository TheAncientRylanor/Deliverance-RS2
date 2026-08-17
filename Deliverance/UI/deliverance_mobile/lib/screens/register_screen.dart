import 'dart:io';

import 'package:deliverance_mobile/models/user.insert.multipart.dart';
import 'package:deliverance_mobile/providers/user_provider.dart';
import 'package:deliverance_mobile/utils/api_client_exception.dart';
import 'package:deliverance_mobile/utils/api_constants.dart';
import 'package:deliverance_mobile/utils/util_widgets.dart';
import 'package:deliverance_mobile/widgets/custom_buttons.dart';
import 'package:deliverance_mobile/widgets/custom_text_field.dart';
import 'package:deliverance_mobile/widgets/custom_toast.dart';
import 'package:deliverance_mobile/widgets/image_holder.dart';
import 'package:deliverance_mobile/widgets/image_picker.dart';
import 'package:deliverance_mobile/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  UserProvider userProvider = UserProvider();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _re_password = TextEditingController();
  File? _selectedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Register"),
        centerTitle: true,
        titleTextStyle: Theme.of(context).textTheme.displayLarge,
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.surface,
        shadowColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsets.only(
                right: 20,
                left: 20,
                bottom: 100,
                top: 20,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 15,
                children: [
                  ProfileAvatar(
                    isEditable: true,
                    onEditTap: _pickProfileImage,
                    child: buildProfileImage(
                      _selectedImage,
                      null,
                      ApiConstants.baseUrl,
                    ),
                  ),
                  CustomTextField(
                    controller: _username,
                    labelText: "Username",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your Username';
                      }
                      return null;
                    },
                  ),
                  CustomTextField(
                    controller: _firstName,
                    labelText: "First name",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your first name';
                      }
                      return null;
                    },
                  ),
                  CustomTextField(
                    controller: _lastName,
                    labelText: "Last name",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your last name';
                      }
                      return null;
                    },
                  ),
                  CustomTextField(
                    controller: _email,
                    labelText: "Email",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  CustomTextField(
                    controller: _password,
                    labelText: "Password",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  CustomTextField(
                    controller: _re_password,
                    labelText: "Re-Password",
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          label: "Cancel",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          onPressed: () {
                            _saveProfile();
                          },
                          label: "Save",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    final tempImage = await pickImage(ImageSource.gallery, _picker);
    if (!mounted) return;
    if (tempImage != null) {
      setState(() {
        _selectedImage = tempImage;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_re_password.text == _password.text) {
        try {
          UserInsertRequest request = UserInsertRequest(
            firstName: _firstName.text,
            lastName: _lastName.text,
            email: _email.text,
            username: _username.text,
            password: _password.text,
            profileImage: _selectedImage,
          );
          await userProvider.insertUser(request);
          showCustomToast(context, "Profile saved successfully");
          await Future.delayed(const Duration(milliseconds: 200));
          if (mounted) Navigator.pop(context);
        } on ApiClientException catch (e) {
          alertBox(context, "Register error", e.message);
        }
      }
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    super.dispose();
  }
}
