import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

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

  void _setPressed(bool value) {
    if (!widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final scale = !reduce && _pressed && widget.enabled ? 0.97 : 1.0;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: scale,
        duration: reduce ? Duration.zero : AppMotion.press,
        curve: AppMotion.ease,
        child: widget.child,
      ),
    );
  }
}

/// One entrance per screen: fade plus an optional short rise. With "reduce
/// motion" the child is shown at once. Opacity does not block hit testing,
/// so a single pump can still reach the controls.
class QuietEntrance extends StatefulWidget {
  const QuietEntrance({
    super.key,
    required this.child,
    this.rise = 0,
    this.delay = Duration.zero,
  });

  final Widget child;

  /// Logical pixels the child travels upward while it fades in.
  final double rise;

  /// Stagger for a second element of the same entrance (≤ 80 ms).
  final Duration delay;

  @override
  State<QuietEntrance> createState() => _QuietEntranceState();
}

class _QuietEntranceState extends State<QuietEntrance>
    with SingleTickerProviderStateMixin {
  // The stagger lives inside the controller (Interval), not in a Timer, so
  // tests never leave a pending timer behind.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.entrance + widget.delay,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      widget.delay.inMicroseconds /
          (AppMotion.entrance + widget.delay).inMicroseconds,
      1,
      curve: AppMotion.ease,
    ),
  );
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faded = FadeTransition(opacity: _curve, child: widget.child);
    if (widget.rise == 0) return faded;
    return AnimatedBuilder(
      animation: _curve,
      child: faded,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, widget.rise * (1 - _curve.value)),
        child: child,
      ),
    );
  }
}
