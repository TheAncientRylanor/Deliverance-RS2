import 'package:flutter/material.dart';

class ContactAvatarPicker extends StatelessWidget {
  final VoidCallback? onPickPhoto;

  const ContactAvatarPicker({super.key, this.onPickPhoto});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 280,
          width: 280,
          child: Center(
            child: Container(
              width: 240,
              height: 240,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(200),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.0,
                ),
              ),
              child: const Center(
                child: Icon(Icons.person, size: 200.0, color: Colors.white),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
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
              onPressed: onPickPhoto ?? () {},
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
