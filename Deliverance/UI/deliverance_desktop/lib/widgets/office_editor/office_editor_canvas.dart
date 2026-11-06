import 'package:deliverance_desktop/utils/constants.dart';
import 'package:deliverance_desktop/widgets/office_editor/placed_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// The area devices are dropped onto and dragged around in. It only reports
/// what the user did; the screen owns the device list and updates it.
///
/// Positions passed to the callbacks are fractions of the canvas size, already
/// clamped so the whole device stays visible.
class OfficeEditorCanvas extends StatefulWidget {
  final List<PlacedDevice> devices;
  final void Function(String type, Offset position) onDeviceDropped;
  final void Function(PlacedDevice device, Offset position) onDeviceMoved;
  final void Function(PlacedDevice device) onDeviceTapped;

  const OfficeEditorCanvas({
    super.key,
    required this.devices,
    required this.onDeviceDropped,
    required this.onDeviceMoved,
    required this.onDeviceTapped,
  });

  @override
  State<OfficeEditorCanvas> createState() => _OfficeEditorCanvasState();
}

class _OfficeEditorCanvasState extends State<OfficeEditorCanvas> {
  // Size of a placed device: an 80px icon plus the IconButton padding, and
  // room for the name below it.
  static const double _deviceWidth = 96;
  static const double _deviceHeight = 120;

  final GlobalKey _canvasKey = GlobalKey();

  /// Keeps a device's top-left corner (as a fraction of the canvas) inside
  /// the canvas, so the whole device stays visible.
  Offset _clamp(Offset fraction, Size canvasSize) {
    final maxX = canvasSize.width > _deviceWidth
        ? (canvasSize.width - _deviceWidth) / canvasSize.width
        : 0.0;
    final maxY = canvasSize.height > _deviceHeight
        ? (canvasSize.height - _deviceHeight) / canvasSize.height
        : 0.0;
    return Offset(fraction.dx.clamp(0.0, maxX), fraction.dy.clamp(0.0, maxY));
  }

  void _handleDrop(DragTargetDetails<String> details) {
    final box = _canvasKey.currentContext!.findRenderObject() as RenderBox;
    // details.offset is the top-left of the drag preview, which is where the
    // device should land.
    final local = box.globalToLocal(details.offset);
    final size = box.size;
    widget.onDeviceDropped(
      details.data,
      _clamp(Offset(local.dx / size.width, local.dy / size.height), size),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: _handleDrop,
      builder: (context, _, _) => LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          // The transparent color makes empty areas accept drops too.
          return Container(
            key: _canvasKey,
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent,
            child: Stack(
              children: [
                for (final device in widget.devices)
                  Positioned(
                    left: device.position.dx * size.width,
                    top: device.position.dy * size.height,
                    child: _CanvasDevice(
                      device: device,
                      onTap: () => widget.onDeviceTapped(device),
                      onDrag: (delta) => widget.onDeviceMoved(
                        device,
                        _clamp(
                          device.position +
                              Offset(
                                delta.dx / size.width,
                                delta.dy / size.height,
                              ),
                          size,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CanvasDevice extends StatelessWidget {
  final PlacedDevice device;
  final VoidCallback onTap;
  final ValueChanged<Offset> onDrag;

  const _CanvasDevice({
    required this.device,
    required this.onTap,
    required this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) => onDrag(details.delta),
      child: Column(
        children: [
          IconButton(
            mouseCursor: SystemMouseCursors.click,
            onPressed: onTap,
            icon: SvgPicture.asset(
              iconForType(device.type),
              width: 80.0,
              height: 80.0,
              colorFilter: deviceColorFilter(device.scout, context),
            ),
          ),
          Text(
            device.details.name ?? "",
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}
