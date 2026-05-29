import 'package:flutter/material.dart';

class AnimatedArrow extends StatefulWidget {
  final String direction;
  final Color color;

  const AnimatedArrow({
    super.key,
    required this.direction,
    required this.color,
  });

  @override
  State<AnimatedArrow> createState() => _AnimatedArrowState();
}

class _AnimatedArrowState extends State<AnimatedArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _offsetAnim = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData get _icon {
    switch (widget.direction) {
      case 'left':
        return Icons.arrow_back;
      case 'right':
        return Icons.arrow_forward;
      case 'up':
        return Icons.arrow_upward;
      case 'down':
        return Icons.arrow_downward;
      default:
        return Icons.center_focus_strong;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.direction == 'none') return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _offsetAnim,
      builder: (context, child) {
        final Offset translate;
        switch (widget.direction) {
          case 'left':
            translate = Offset(-_offsetAnim.value, 0);
            break;
          case 'right':
            translate = Offset(_offsetAnim.value, 0);
            break;
          case 'up':
            translate = Offset(0, -_offsetAnim.value);
            break;
          case 'down':
            translate = Offset(0, _offsetAnim.value);
            break;
          default:
            translate = Offset.zero;
        }
        return Transform.translate(
          offset: translate,
          child: Icon(_icon, size: 56, color: widget.color),
        );
      },
    );
  }
}
