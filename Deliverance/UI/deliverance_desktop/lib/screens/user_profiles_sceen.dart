import 'package:deliverance_desktop/models/search_models/user_search_object.dart';
import 'package:deliverance_desktop/models/search_result.dart';
import 'package:deliverance_desktop/models/user.dart';
import 'package:deliverance_desktop/providers/user_provider.dart';
import 'package:deliverance_desktop/utils/api_client_exception.dart';
import 'package:deliverance_desktop/utils/util_widgets.dart';
import 'package:deliverance_desktop/widgets/custom_paginator.dart';
import 'package:deliverance_desktop/widgets/search_sort_header.dart';
import 'package:deliverance_desktop/widgets/user_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserProfilesSceen extends StatefulWidget {
  const UserProfilesSceen({super.key});

  @override
  State<UserProfilesSceen> createState() => _UserProfilesSceenState();
}

class _UserProfilesSceenState extends State<UserProfilesSceen> {
  late UserProvider _userProvider;
  SearchResult<User> _userList = SearchResult();
  final UserSearchObject _userSearchObject = UserSearchObject();
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    _userProvider = context.read<UserProvider>();
    initValues();
  }

  Future<void> initValues() async {
    try {
      _userList = await _userProvider.get(filter: _userSearchObject.toJson());
    } on ApiClientException catch (e) {
      if (!mounted) return;
      alertBoxMoveBack(context, "User error", e.message, onRetry: initValues);
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: isLoading
          ? globalLoadingSpinner()
          : Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  SearchSortHeader(
                    searchHint: "Search users by username...",
                    sortDialogTitle: "Sort users",
                    sortColumns: const {
                      'Username': 'Username',
                      'Email': 'Email',
                      'CreatedAt': 'Date created',
                    },
                    currentSortBy: _userSearchObject.sortBy,
                    currentDescending: _userSearchObject.descending ?? true,
                    onSearch: (value) {
                      _userSearchObject.username = value;
                      _userSearchObject.page = 1;
                      initValues();
                    },
                    onSort: (sortBy, descending) {
                      _userSearchObject.sortBy = sortBy;
                      _userSearchObject.descending = descending;
                      _userSearchObject.page = 1;
                      initValues();
                    },
                  ),
                  const SizedBox(height: 80),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Wrap(
                      spacing: 40,
                      runSpacing: 30,
                      children: [
                        for (var user in _userList.items ?? [])
                          RepaintBoundary(
                            key: ValueKey(user.uuid),
                            child: UserCard(user: user),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  CustomPaginator(
                    currentPage: _userSearchObject.page ?? 1,
                    totalPages: _userList.totalPages ?? 1,
                    pageSize: _userSearchObject.pageSize ?? 4,
                    searchObject: _userSearchObject,
                    onChanged: initValues,
                  ),
                ],
              ),
            ),
    );
  }
}
