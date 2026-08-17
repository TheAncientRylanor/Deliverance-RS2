import 'package:flutter/material.dart';

enum ToastType { info, success, error }

OverlayEntry? _activeToastEntry;

void showCustomToast(
  BuildContext context,
  String message, {
  ToastType type = ToastType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  _activeToastEntry?.remove();

  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => _ToastWidget(
      message: message,
      type: type,
      duration: duration,
      onDismissed: () {
        overlayEntry.remove();
        if (_activeToastEntry == overlayEntry) _activeToastEntry = null;
      },
    ),
  );

  _activeToastEntry = overlayEntry;
  overlay.insert(overlayEntry);
}

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
    _scheduleDismiss();
  }

  Future<void> _scheduleDismiss() async {
    await Future.delayed(widget.duration);
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ({Color background, IconData icon}) get _style {
    switch (widget.type) {
      case ToastType.success:
        return (
          background: const Color(0xFF2E7D32),
          icon: Icons.check_circle_rounded,
        );
      case ToastType.error:
        return (background: const Color(0xFFC62828), icon: Icons.error_rounded);
      case ToastType.info:
        return (
          background: Theme.of(context).colorScheme.primary,
          icon: Icons.info_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;

    return Positioned(
      top: 60,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: style.background,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: style.background.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(style.icon, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
