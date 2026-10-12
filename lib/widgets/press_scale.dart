import 'package:flutter/material.dart';

/// Press feedback on the compositor (scale only). Idle scale stays 1,
/// so the first frame does not move layout.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  static const _curve = Cubic(0.23, 1, 0.32, 1);

  void _setPressed(bool value) {
    if (!widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final scale = !reduce && _pressed && widget.enabled ? 0.98 : 1.0;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: scale,
        duration: reduce ? Duration.zero : const Duration(milliseconds: 120),
        curve: _curve,
        child: widget.child,
      ),
    );
  }
}

/// One entrance per screen. The first frame stays fully visible so a
/// single pump can still hit the controls.
class QuietEntrance extends StatefulWidget {
  const QuietEntrance({super.key, required this.child});

  final Widget child;

  @override
  State<QuietEntrance> createState() => _QuietEntranceState();
}

class _QuietEntranceState extends State<QuietEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) return;
      _controller.value = 0;
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.23, 1, 0.32, 1),
      ),
      child: widget.child,
    );
  }
}
