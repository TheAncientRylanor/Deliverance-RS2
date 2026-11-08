import 'dart:math';

import 'package:deliverance_desktop/widgets/custom_buttons.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class OfficeEditorToolbar extends StatefulWidget {
  final VoidCallback onSave;
  final VoidCallback? onCancel;
  final bool isSaving;

  const OfficeEditorToolbar({
    super.key,
    required this.onSave,
    required this.onCancel,
    required this.isSaving,
  });

  @override
  State<OfficeEditorToolbar> createState() => _OfficeEditorToolbarState();
}

class _OfficeEditorToolbarState extends State<OfficeEditorToolbar> {
  static const double _openHeight = 200;
  static const double _collapsedHeight = 80;
  static const double _minOpenContentWidth = 420;
  static const Duration _animationDuration = Duration(milliseconds: 250);

  bool _isOpen = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: _animationDuration,
      curve: Curves.easeInOut,
      height: _isOpen ? _openHeight : _collapsedHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: max(
              constraints.maxWidth,
              _isOpen ? _minOpenContentWidth : 0,
            ),
            height: constraints.maxHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isOpen) ...[
                  _ModeButton(icon: FontAwesomeIcons.eye, label: "View mode"),
                  const _Gap(100),
                  _ModeButton(
                    icon: FontAwesomeIcons.penToSquare,
                    label: "Edit mode",
                  ),
                  const _Gap(400),
                  Column(
                    spacing: 10,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: PrimaryButton(
                          onPressed: widget.onSave,
                          isLoading: widget.isSaving,
                          label: "Save",
                        ),
                      ),
                      Flexible(
                        child: SecondaryButton(
                          onPressed: widget.onCancel,
                          label: "Cancel",
                        ),
                      ),
                    ],
                  ),
                  const _Gap(100),
                ],
                IconButton(
                  icon: Icon(
                    _isOpen ? Icons.arrow_downward : Icons.arrow_upward,
                  ),
                  color: theme.colorScheme.primary,
                  iconSize: 30,
                  onPressed: () => setState(() => _isOpen = !_isOpen),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Gap extends StatelessWidget {
  final double width;

  const _Gap(this.width);

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: width.round(),
      child: SizedBox(width: width),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final FaIconData icon;
  final String label;

  const _ModeButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: IconButton(
            onPressed: () {},
            icon: FaIcon(icon, size: 60, color: Colors.white),
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
