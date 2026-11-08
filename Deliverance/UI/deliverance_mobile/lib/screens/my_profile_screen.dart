import 'dart:io';
import 'package:deliverance_mobile/models/user.update.multipart.dart';
import 'package:deliverance_mobile/providers/auth_provider.dart';
import 'package:deliverance_mobile/providers/user_provider.dart';
import 'package:deliverance_mobile/utils/api_client_exception.dart';
import 'package:deliverance_mobile/utils/api_constants.dart';
import 'package:deliverance_mobile/utils/form_validators.dart';
import 'package:deliverance_mobile/utils/server_field_errors.dart';
import 'package:deliverance_mobile/utils/util_widgets.dart';
import 'package:deliverance_mobile/widgets/custom_buttons.dart';
import 'package:deliverance_mobile/widgets/custom_text_field.dart';
import 'package:deliverance_mobile/widgets/custom_toast.dart';
import 'package:deliverance_mobile/widgets/dialogs/reset_password_dialog.dart';
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
  bool _isLoggingOut = false;
  bool _isUsernameUsed = false;
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
      alertBox(context, "Error", e.message, mode: AlertBoxMode.ok);
    }
  }

  void initValues() {
    final user = _userProvider.data;
    _usernameController.text = user?.username ?? "";
    _emailController.text = user?.email ?? "";
    _lastNameController.text = user?.lastName ?? "";
    _firstNameController.text = user?.firstName ?? "";
  }

  void toggleEdit() {
    setState(() {
      isReadOnly = !isReadOnly;
    });
  }

  String get editButtonText => isReadOnly ? "Edit" : "Save";
  String get cancelButtonText => isReadOnly ? "Log out" : "Cancel";
  Future<void> onEditButtonPressed() async {
    if (isReadOnly) {
      toggleEdit();
    } else {
      await saveValues();
    }
  }

  Future<void> onCancelButtonPressed() async {
    if (isReadOnly) {
      final result = await alertBox(
        context,
        "Confirmation",
        "Are you sure that you want to log out?",
      );
      if (result != true) return;
      setState(() => _isLoggingOut = true);
      try {
        await _authProvider.logout();
        if (!mounted) return;
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      } on ApiClientException catch (e) {
        if (!mounted) return;
        alertBox(context, "Error", e.toString());
      } finally {
        if (mounted) setState(() => _isLoggingOut = false);
      }
    } else {
      setState(() {
        initValues();
        _selectedImage = null;
        _isUsernameUsed = false;
        isReadOnly = true;
      });
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

  Future<void> saveValues() async {
    await checkUsernameUsage();
    if (!mounted) return;
    _serverErrors.clear();
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
        await _userProvider.updateUser(_userProvider.data!.uuid!, newRequest);
        if (!mounted) return;
        setState(() {
          isReadOnly = true;
          _selectedImage = null;
        });
        showCustomToast(
          context,
          "Your profile (${newRequest.username}) was saved.",
          type: ToastType.success,
        );
      } on ApiClientException catch (e) {
        if (!mounted) return;
        if (!_serverErrors.show(e, _formKey)) {
          alertBox(context, "Update error", e.message);
        }
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 1.0,
                                ),
                              ),
                              child: Center(
                                child: ClipOval(
                                  child: buildProfileImage(
                                    _selectedImage,
                                    _userProvider.data?.imagePath ?? "",
                                    ApiConstants.baseUrl,
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
                                  color: Theme.of(context).colorScheme.primary,
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
                                  color: Theme.of(context).colorScheme.primary,
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
                              validator: _serverErrors.wrap('FirstName', personName('First name')),
                            ),
                            CustomTextField(
                              controller: _lastNameController,
                              labelText: "Last name",
                              readOnly: isReadOnly,
                              validator: _serverErrors.wrap('LastName', personName('Last name')),
                            ),
                            CustomTextField(
                              controller: _usernameController,
                              focusNode: _usernameFocusNode,
                              formFieldKey: _usernameFieldKey,
                              labelText: "Username",
                              readOnly: isReadOnly,
                              validator: _serverErrors.wrap('Username', allOf([username(), (_) => _isUsernameUsed ? 'This username is already taken. Choose a different username.' : null])),
                            ),
                            CustomTextField(
                              controller: _emailController,
                              labelText: "Email",
                              readOnly: isReadOnly,
                              validator: _serverErrors.wrap('Email', email()),
                            ),
                            !isReadOnly
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        spacing: 8,
                                        children: [
                                          Text(
                                            "Password",
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
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
                                            onPressed: onResetPasswordPressed,
                                            label: "Reset",
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                : const SizedBox(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 60,
                        horizontal: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              isLoading: _isLoggingOut,
                              onPressed: onCancelButtonPressed,
                              label: cancelButtonText,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PrimaryButton(
                              onPressed: onEditButtonPressed,
                              label: editButtonText,
                              isLoading: isLoading,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
