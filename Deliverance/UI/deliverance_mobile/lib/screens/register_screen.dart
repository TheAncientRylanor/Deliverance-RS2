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
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormFieldState> _usernameFieldKey =
      GlobalKey<FormFieldState>();
  UserProvider userProvider = UserProvider();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  // ignore: non_constant_identifier_names
  final TextEditingController _re_password = TextEditingController();
  late FocusNode _userNameFocusNode;
  File? _selectedImage;
  bool _isSaving = false;
  bool _isUsernameUsed = false;
  bool _obscurePassword = true;
  @override
  void initState() {
    super.initState();
    _userNameFocusNode = FocusNode();
    _userNameFocusNode.addListener(_handleFocusChange);
    userProvider = context.read<UserProvider>();
  }

  @override
  void dispose() {
    _userNameFocusNode.removeListener(_handleFocusChange);
    _userNameFocusNode.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _re_password.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_userNameFocusNode.hasFocus) {
      checkUsernameUsage().then((_) {
        // Validate only the username field so other empty fields don't light up.
        if (mounted) _usernameFieldKey.currentState?.validate();
      });
    }
  }

  Future<void> checkUsernameUsage() async {
    final username = _username.text.trim();
    if (username.isEmpty) {
      if (_isUsernameUsed) setState(() => _isUsernameUsed = false);
      return;
    }
    try {
      var result = await userProvider.userNameExist(username);
      if (!mounted) return;
      setState(() {
        _isUsernameUsed = result;
      });
    } on ApiClientException catch (e) {
      if (!mounted) return;
      alertBox(context, "Error", e.message, mode: AlertBoxMode.ok);
    }
  }

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
                    focusNode: _userNameFocusNode,
                    formFieldKey: _usernameFieldKey,
                    labelText: "Username",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your Username';
                      }
                      if (_isUsernameUsed) {
                        return "Username is used. Try different one";
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
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  CustomTextField(
                    controller: _re_password,
                    labelText: "Re-Password",
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value != _password.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
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
                          isLoading: _isSaving,
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
    await checkUsernameUsage();
    if (!mounted) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
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
        if (!mounted) return;
        showCustomToast(context, "Profile saved successfully");
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) Navigator.pop(context);
      } on ApiClientException catch (e) {
        if (!mounted) return;
        alertBox(context, "Register error", e.message, mode: AlertBoxMode.ok);
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }
}
