import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThreeDButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color color;
  final double height;
  final double width;
  final bool isFloating;

  const ThreeDButton({
    super.key,
    required this.child,
    this.onPressed,
    this.color = Colors.teal,
    this.height = 50,
    this.width = double.infinity,
    this.isFloating = false,
  });

  @override
  State<ThreeDButton> createState() => _ThreeDButtonState();
}

class _ThreeDButtonState extends State<ThreeDButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 4.0).animate(_controller);
    
    if (widget.isFloating) {
      _startFloatingAnimation();
    }
  }

  void _startFloatingAnimation() {
     // Optional: Add a separate controller for continuous floating
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onPressed?.call();
        HapticFeedback.mediumImpact();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                // Depth shadow (3D effect)
                BoxShadow(
                  color: Color.lerp(widget.color, Colors.black, 0.4)!,
                  offset: Offset(0, 4 - _animation.value),
                  blurRadius: 0,
                ),
                // Soft shadow (Ambient)
                if (!_isPressed)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(0, 8),
                    blurRadius: 10,
                  ),
              ],
            ),
            child: Transform.translate(
              offset: Offset(0, _animation.value),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: widget.child),
              ),
            ),
          );
        },
      ),
    );
  }
}
