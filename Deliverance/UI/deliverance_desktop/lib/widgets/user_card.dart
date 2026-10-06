import 'package:deliverance_desktop/layouts/master_screen.dart';
import 'package:deliverance_desktop/models/user.dart';
import 'package:deliverance_desktop/providers/selected_user_provider.dart';
import 'package:deliverance_desktop/screens/single_user_screen.dart';
import 'package:deliverance_desktop/utils/api_constants.dart';
import 'package:deliverance_desktop/widgets/image_holder.dart';
import 'package:deliverance_desktop/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserCard extends StatefulWidget {
  final VoidCallback? onTap;
  final double width;
  final double height;
  final User user;

  const UserCard({
    super.key,
    this.onTap,
    this.width = 250,
    this.height = 320,
    required this.user,
  });

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final fullName = [
      widget.user.firstName,
      widget.user.lastName,
    ].where((part) => part != null && part.isNotEmpty).join(' ');

    return AnimatedScale(
      scale: _hover ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final SelectedUserProvider selectedUserProvider = context
                .read<SelectedUserProvider>();
            selectedUserProvider.select(widget.user);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MasterScreen(
                  title: "Single user",
                  child: SingleUserScreen(user: widget.user),
                ),
              ),
            );
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: Card(
              elevation: 10,
              shadowColor: Colors.black,
              color: Theme.of(context).colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
                side: BorderSide(
                  width: 1,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              child: SizedBox(
                height: widget.height,
                width: widget.width,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ProfileAvatar(
                      isEditable: false,
                      onEditTap: () {},
                      width: 190,
                      height: 190,
                      containerHeight: 150,
                      containerWidth: 150,
                      child: buildProfileImage(
                        null,
                        widget.user.imagePath,
                        ApiConstants.baseUrl,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      fullName.isEmpty ? '-' : fullName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.user.username ?? '-',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w100,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
