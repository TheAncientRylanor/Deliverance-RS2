import 'dart:io';

import 'package:deliverance_mobile/models/user.insert.multipart.dart';
import 'package:deliverance_mobile/providers/user_provider.dart';
import 'package:deliverance_mobile/utils/api_client_exception.dart';
import 'package:deliverance_mobile/utils/api_constants.dart';
import 'package:deliverance_mobile/utils/form_validators.dart';
import 'package:deliverance_mobile/utils/server_field_errors.dart';
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
  final ServerFieldErrors _serverErrors = ServerFieldErrors();
  final GlobalKey<FormFieldState> _usernameFieldKey =
      GlobalKey<FormFieldState>();
  UserProvider userProvider = UserProvider();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
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
    _confirmPassword.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_userNameFocusNode.hasFocus) {
      checkUsernameUsage().then((_) {
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
                    validator: _serverErrors.wrap(
                      'Username',
                      allOf([
                        username(),
                        (_) => _isUsernameUsed
                            ? 'This username is already taken. Choose a different username.'
                            : null,
                      ]),
                    ),
                  ),
                  CustomTextField(
                    controller: _firstName,
                    labelText: "First name",
                    validator: _serverErrors.wrap(
                      'FirstName',
                      personName('First name'),
                    ),
                  ),
                  CustomTextField(
                    controller: _lastName,
                    labelText: "Last name",
                    validator: _serverErrors.wrap(
                      'LastName',
                      personName('Last name'),
                    ),
                  ),
                  CustomTextField(
                    controller: _email,
                    labelText: "Email",
                    keyboardType: TextInputType.emailAddress,
                    validator: _serverErrors.wrap('Email', email()),
                  ),
                  CustomTextField(
                    controller: _password,
                    labelText: "Password",
                    obscureText: _obscurePassword,
                    validator: _serverErrors.wrap(
                      'Password',
                      password('Password'),
                    ),
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
                    controller: _confirmPassword,
                    labelText: "Repeat password",
                    obscureText: _obscurePassword,
                    validator: allOf([
                      requiredField('Repeated password'),
                      sameAs(
                        () => _password.text,
                        'Passwords do not match. Enter the same password twice.',
                      ),
                    ]),
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
    _serverErrors.clear();
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
        showCustomToast(
          context,
          "Account ${request.username} created. You can now log in.",
        );
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) Navigator.pop(context);
      } on ApiClientException catch (e) {
        if (!mounted) return;
        if (!_serverErrors.show(e, _formKey)) {
          alertBox(context, "Register error", e.message, mode: AlertBoxMode.ok);
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }
}
