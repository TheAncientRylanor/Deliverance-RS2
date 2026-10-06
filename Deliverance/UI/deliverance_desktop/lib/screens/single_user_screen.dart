import 'package:deliverance_desktop/models/report.dart';
import 'package:deliverance_desktop/models/report_status_filter.dart';
import 'package:deliverance_desktop/models/search_models/report_search_object.dart';
import 'package:deliverance_desktop/models/search_result.dart';
import 'package:deliverance_desktop/models/user.dart';
import 'package:deliverance_desktop/providers/report_provider.dart';
import 'package:deliverance_desktop/utils/api_client_exception.dart';
import 'package:deliverance_desktop/utils/api_constants.dart';
import 'package:deliverance_desktop/utils/util_widgets.dart';
import 'package:deliverance_desktop/widgets/custom_buttons.dart';
import 'package:deliverance_desktop/widgets/custom_text_field.dart';
import 'package:deliverance_desktop/widgets/image_holder.dart';
import 'package:deliverance_desktop/widgets/profile_avatar.dart';
import 'package:deliverance_desktop/widgets/reports_child.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SingleUserScreen extends StatefulWidget {
  final User user;

  const SingleUserScreen({super.key, required this.user});
  @override
  State<SingleUserScreen> createState() => _SingleUserScreen();
}

class _SingleUserScreen extends State<SingleUserScreen> {
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final ReportProvider _reportProvider;
  SearchResult<Report> _reportList = SearchResult();
  bool isLoading = true;
  ReportSearchObject reportSearchObject = ReportSearchObject(
    status: ReportStatusFilter.active,
  );
  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _reportProvider = context.read<ReportProvider>();
    reportSearchObject.userId = widget.user.uuid;
    initValues();
  }

  Future<void> initValues() async {
    final user = widget.user;
    _usernameController.text = user.username ?? "";
    _emailController.text = user.email ?? "";
    _firstNameController.text = user.firstName ?? "";
    _lastNameController.text = user.lastName ?? "";
    try {
      _reportList = await _reportProvider.get(
        filter: reportSearchObject.toJson(),
      );
    } on ApiClientException catch (e) {
      if (!mounted) return;
      alertBoxMoveBack(context, "Error", e.message, onRetry: initValues);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _buildAvatar(BuildContext context) {
    return ProfileAvatar(
      isEditable: false,
      onEditTap: () {},
      height: 220,
      width: 220,
      containerHeight: 190,
      containerWidth: 190,
      child: buildProfileImage(
        null,
        widget.user.imagePath ?? "",
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
      child: isLoading
          ? globalLoadingSpinner()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 60,
                    horizontal: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _usernameController.text,
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      const SizedBox(height: 40),
                      _buildAvatar(context),
                      const SizedBox(height: 40),
                      Column(
                        spacing: 20,
                        children: [
                          _buildFormRow(
                            CustomTextField(
                              controller: _firstNameController,
                              labelText: "First name",
                              readOnly: true,
                            ),
                            CustomTextField(
                              controller: _lastNameController,
                              labelText: "Last name",
                              readOnly: true,
                            ),
                          ),
                          _buildFormRow(
                            CustomTextField(
                              controller: _usernameController,
                              labelText: "Username",
                              readOnly: true,
                            ),
                            CustomTextField(
                              controller: _emailController,
                              labelText: "Email",
                              readOnly: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 60),
                      PrimaryButton(
                        onPressed: () {},
                        label: "Disable account",
                        width: 180,
                      ),
                      const SizedBox(height: 60),
                      Text(
                        "Reports from ${_usernameController.text}",
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      const SizedBox(height: 20),
                      (_reportList.items?.isEmpty ?? true)
                          ? Center(
                              child: Text(
                                "No fresh reports found!",
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            )
                          : ReportsChild(reportList: _reportList),
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }
}
