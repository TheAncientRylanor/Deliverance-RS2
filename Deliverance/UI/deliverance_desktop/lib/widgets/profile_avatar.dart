import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final Widget child;
  final bool isEditable;
  final VoidCallback onEditTap;
  final double? height;
  final double? width;
  final double? containerHeight;
  final double? containerWidth;
  const ProfileAvatar({
    required this.child,
    required this.isEditable,
    required this.onEditTap,
    this.height,
    this.width,
    this.containerHeight,
    this.containerWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: height ?? 280,
          width: width ?? 280,
          child: Align(
            alignment: Alignment.center,
            child: Container(
              width: containerWidth ?? 240,
              height: containerHeight ?? 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(200),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.0,
                ),
              ),
              child: Center(child: ClipOval(child: child)),
            ),
          ),
        ),

        if (isEditable)
          Positioned(
            bottom: 5,
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
                onPressed: onEditTap,
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
