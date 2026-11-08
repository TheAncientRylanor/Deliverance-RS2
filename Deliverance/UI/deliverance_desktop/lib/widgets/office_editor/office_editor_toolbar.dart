import 'dart:math';

import 'package:deliverance_desktop/widgets/custom_buttons.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class OfficeEditorToolbar extends StatefulWidget {
  final VoidCallback onSave;
  final VoidCallback? onCancel;
  final bool isSaving;
  final bool isViewMode;
  final ValueChanged<bool> onViewModeChanged;

  const OfficeEditorToolbar({
    super.key,
    required this.isViewMode,
    required this.onViewModeChanged,
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
  void didUpdateWidget(OfficeEditorToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isViewMode != oldWidget.isViewMode) {
      _isOpen = !widget.isViewMode;
    }
  }

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
                  _ModeButton(
                    icon: FontAwesomeIcons.eye,
                    label: "View mode",
                    isActive: widget.isViewMode,
                    onPressed: () => widget.onViewModeChanged(true),
                  ),
                  const _Gap(100),
                  _ModeButton(
                    icon: FontAwesomeIcons.penToSquare,
                    label: "Edit mode",
                    isActive: !widget.isViewMode,
                    onPressed: () => widget.onViewModeChanged(false),
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
                if (!_isOpen && widget.isViewMode) ...[
                  Text(
                    "View mode: the office is locked",
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(width: 20),
                  SecondaryButton(
                    onPressed: () => widget.onViewModeChanged(false),
                    label: "Edit mode",
                  ),
                  const SizedBox(width: 20),
                ] else
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
  final bool isActive;
  final VoidCallback onPressed;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive ? theme.colorScheme.primary : Colors.white;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: IconButton(
            onPressed: isActive ? null : onPressed,
            icon: FaIcon(icon, size: 60, color: color),
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: isActive ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }
}
