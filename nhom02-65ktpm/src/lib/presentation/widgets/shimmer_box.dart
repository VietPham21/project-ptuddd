import 'package:flutter/material.dart';

/// Khối "shimmer" giả lập nội dung đang tải (không cần thêm package).
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({super.key, this.height = 72, this.width = double.infinity, this.radius = 16});

  final double height;
  final double width;
  final double radius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = scheme.surface;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          height: widget.height,
          width: widget.width,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * t - 1, 0),
              end: Alignment(-1 + 2 * t + 1, 0),
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}
