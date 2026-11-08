import 'dart:io';

import 'package:deliverance_desktop/models/user.update.multipart.dart';
import 'package:deliverance_desktop/providers/auth_provider.dart';
import 'package:deliverance_desktop/providers/user_provider.dart';
import 'package:deliverance_desktop/utils/api_client_exception.dart';
import 'package:deliverance_desktop/utils/api_constants.dart';
import 'package:deliverance_desktop/utils/form_validators.dart';
import 'package:deliverance_desktop/utils/server_field_errors.dart';
import 'package:deliverance_desktop/utils/util_widgets.dart';
import 'package:deliverance_desktop/widgets/custom_buttons.dart';
import 'package:deliverance_desktop/widgets/custom_text_field.dart';
import 'package:deliverance_desktop/widgets/custom_toast.dart';
import 'package:deliverance_desktop/widgets/dialogs/reset_password_dialog.dart';
import 'package:deliverance_desktop/widgets/image_holder.dart';
import 'package:deliverance_desktop/widgets/image_picker.dart';
import 'package:deliverance_desktop/widgets/profile_avatar.dart';
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
  final ServerFieldErrors _serverErrors = ServerFieldErrors();
  final GlobalKey<FormFieldState> _usernameFieldKey =
      GlobalKey<FormFieldState>();
  late AuthProvider _authProvider;
  late UserProvider _userProvider;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final FocusNode _usernameFocusNode;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;
  bool isReadOnly = true;
  bool _isUsernameUsed = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
    _userProvider = context.read<UserProvider>();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _usernameFocusNode = FocusNode();
    _usernameFocusNode.addListener(_handleUsernameFocusChange);
    initValues();
  }

  void _handleUsernameFocusChange() {
    if (!_usernameFocusNode.hasFocus && !isReadOnly) {
      checkUsernameUsage().then((_) {
        if (mounted) _usernameFieldKey.currentState?.validate();
      });
    }
  }

  Future<void> checkUsernameUsage() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty || username == _userProvider.data?.username) {
      if (_isUsernameUsed) setState(() => _isUsernameUsed = false);
      return;
    }
    try {
      final result = await _userProvider.userNameExist(username);
      if (!mounted) return;
      setState(() {
        _isUsernameUsed = result;
      });
    } on ApiClientException catch (e) {
      if (!mounted) return;
      alertBox(context, "Error", e.message);
    }
  }

  void initValues() {
    final user = _userProvider.data;
    _usernameController.text = user?.username ?? "";
    _emailController.text = user?.email ?? "";
    _firstNameController.text = user?.firstName ?? "";
    _lastNameController.text = user?.lastName ?? "";
  }

  void toggleEdit() {
    setState(() {
      isReadOnly = !isReadOnly;
    });
  }

  String get editButtonText => isReadOnly ? "Edit" : "Save";
  String get logOutButtonText => isReadOnly ? "Log out" : "Cancel";
  Future<void> onEditButtonPressed() async {
    if (isReadOnly) {
      toggleEdit();
    } else {
      await saveValues();
    }
  }

  Future<void> onCancelButtonPressed() async {
    if (isReadOnly) {
      await _onLogoutPressed();
    } else {
      setState(() {
        initValues();
        _selectedImage = null;
        _isUsernameUsed = false;
        isReadOnly = true;
        _formKey.currentState!.clearError();
      });
    }
  }

  Future<void> saveValues() async {
    await checkUsernameUsage();
    if (!mounted) return;
    _serverErrors.clear();
    if (!_formKey.currentState!.validate()) return;
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
      if (!mounted) return;
      showCustomToast(
        context,
        "Your profile (${newRequest.username}) was saved.",
        type: ToastType.success,
      );
      setState(() {
        isReadOnly = true;
        _selectedImage = null;
      });
    } on ApiClientException catch (e) {
      if (!mounted) return;
      if (!_serverErrors.show(e, _formKey)) {
        alertBox(context, "Update error", e.message);
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _onLogoutPressed() async {
    final result = await alertBox(
      context,
      "Confirmation",
      "Are you sure that you want to log out?",
      mode: AlertBoxMode.choice,
    );
    if (result != true || !mounted) return;
    setState(() => _isLoggingOut = true);
    try {
      await _authProvider.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } on ApiClientException catch (e) {
      if (!mounted) return;
      alertBox(context, "Error", e.message);
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  Future<void> onResetPasswordPressed() async {
    final changed = await resetPasswordDialog(context);
    if (changed != true || !mounted) return;
    showCustomToast(
      context,
      "Password changed. Please sign in with your new password.",
      type: ToastType.success,
    );
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Widget _buildAvatar(BuildContext context) {
    return ProfileAvatar(
      isEditable: !isReadOnly,
      height: 220,
      width: 220,
      containerHeight: 190,
      containerWidth: 190,
      onEditTap: () async {
        final tempImage = await pickImage(ImageSource.gallery, _picker);
        if (!mounted) return;
        if (tempImage != null) {
          setState(() {
            _selectedImage = tempImage;
          });
        }
      },
      child: buildProfileImage(
        _selectedImage,
        _userProvider.data?.imagePath ?? "",
        ApiConstants.baseUrl,
      ),
    );
  }

  Widget _buildFormRow(Widget left, Widget right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 24,
      children: [
        Expanded(child: left),
        Expanded(child: right),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "My Profile",
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 40),
                _buildAvatar(context),
                const SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    spacing: 20,
                    children: [
                      _buildFormRow(
                        CustomTextField(
                          controller: _firstNameController,
                          labelText: "First name",
                          readOnly: isReadOnly,
                          validator: _serverErrors.wrap(
                            'FirstName',
                            personName('First name'),
                          ),
                        ),
                        CustomTextField(
                          controller: _lastNameController,
                          labelText: "Last name",
                          readOnly: isReadOnly,
                          validator: _serverErrors.wrap(
                            'LastName',
                            personName('Last name'),
                          ),
                        ),
                      ),
                      _buildFormRow(
                        CustomTextField(
                          controller: _usernameController,
                          focusNode: _usernameFocusNode,
                          formFieldKey: _usernameFieldKey,
                          labelText: "Username",
                          readOnly: isReadOnly,
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
                          controller: _emailController,
                          labelText: "Email",
                          readOnly: isReadOnly,
                          validator: _serverErrors.wrap('Email', email()),
                        ),
                      ),
                      if (!isReadOnly)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 8,
                            children: [
                              Text(
                                "Password",
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: const Color.fromRGBO(
                                        255,
                                        255,
                                        255,
                                        1.00,
                                      ),
                                    ),
                              ),
                              PrimaryButton(
                                onPressed: isLoading
                                    ? null
                                    : onResetPasswordPressed,
                                label: "Reset",
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SecondaryButton(
                      onPressed: isLoading ? null : onCancelButtonPressed,
                      label: logOutButtonText,
                      isLoading: _isLoggingOut,
                      width: 180,
                    ),
                    PrimaryButton(
                      onPressed: _isLoggingOut ? null : onEditButtonPressed,
                      label: editButtonText,
                      isLoading: isLoading,
                      width: 180,
                    ),
                  ],
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
    _usernameFocusNode.removeListener(_handleUsernameFocusChange);
    _usernameFocusNode.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }
}
