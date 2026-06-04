import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final Color glow;
  final String luxName;

  const TypingIndicator({required this.glow, required this.luxName});

  @override
  State<TypingIndicator> createState() => TypingIndicatorState();
}

class TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulse = Tween(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulse,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: widget.glow.withOpacity(0.2),
              child: Text(
                widget.luxName[0],
                style: TextStyle(
                  color: widget.glow,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AnimatedDot(delay: 0, glow: widget.glow),
                  const SizedBox(width: 4),
                  _AnimatedDot(delay: 0.2, glow: widget.glow),
                  const SizedBox(width: 4),
                  _AnimatedDot(delay: 0.4, glow: widget.glow),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _AnimatedDot extends StatefulWidget {
  final double delay;
  final Color glow;

  const _AnimatedDot({required this.delay, required this.glow});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = (_controller.value - widget.delay).clamp(0.0, 1.0);
        return Transform.scale(
          scale: 0.5 + 0.5 * (1 - (value * 2 - 1).abs()),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: widget.glow,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
