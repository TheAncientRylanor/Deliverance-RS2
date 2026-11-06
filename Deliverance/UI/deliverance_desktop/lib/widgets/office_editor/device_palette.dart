import 'package:deliverance_desktop/utils/constants.dart';
import 'package:deliverance_desktop/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// Collapsible left sidebar of the office editor. Lists the device types that
/// can be dragged onto the canvas; the drag data is the type's name.
class DevicePalette extends StatefulWidget {
  const DevicePalette({super.key});

  @override
  State<DevicePalette> createState() => _DevicePaletteState();
}

class _DevicePaletteState extends State<DevicePalette> {
  static const double _openWidth = 250;
  static const double _collapsedWidth = 80;
  static const Duration _animationDuration = Duration(milliseconds: 250);
  static const List<String> _deviceTypes = [
    "Computer",
    "Laptop",
    "Server",
    "Switch",
    "Router",
  ];

  final _searchController = TextEditingController();
  bool _isOpen = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _visibleTypes {
    final query = _searchController.text.trim().toLowerCase();
    return _deviceTypes
        .where((type) => type.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleTypes = _visibleTypes;
    return AnimatedContainer(
      duration: _animationDuration,
      curve: Curves.easeInOut,
      width: _isOpen ? _openWidth : _collapsedWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          spacing: 20,
          children: [
            IconButton(
              icon: Icon(
                _isOpen ? Icons.arrow_back_outlined : Icons.arrow_forward,
              ),
              color: theme.colorScheme.primary,
              iconSize: 30,
              onPressed: () => setState(() => _isOpen = !_isOpen),
            ),
            if (_isOpen) ...[
              CustomTextField(
                controller: _searchController,
                labelText: "Search device",
              ),
              const SizedBox(height: 50),
              for (final type in visibleTypes) _PaletteItem(type: type),
              if (visibleTypes.isEmpty)
                Text("No matching devices", style: theme.textTheme.labelSmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaletteItem extends StatelessWidget {
  final String type;

  const _PaletteItem({required this.type});

  Widget _icon(double size) => SvgPicture.asset(
    iconForType(type),
    width: size,
    height: size,
    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      children: [
        Draggable<String>(
          data: type,
          // Same size as the device on the canvas, so it lands where it's
          // dropped.
          feedback: Material(color: Colors.transparent, child: _icon(80)),
          // Keeps its size while dragging so the list below doesn't jump.
          childWhenDragging: Opacity(opacity: 0.3, child: _icon(50)),
          child: _icon(50),
        ),
        Text(type, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
