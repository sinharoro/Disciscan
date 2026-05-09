import 'package:flutter/material.dart';
import '../theme.dart';

class ScanBracket extends StatefulWidget {
  final double size;
  final Color color;

  const ScanBracket({
    super.key,
    this.size = 280,
    this.color = AppColors.amber,
  });

  @override
  State<ScanBracket> createState() => _ScanBracketState();
}

class _ScanBracketState extends State<ScanBracket>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _BracketPainter(
              color: widget.color,
            ),
          ),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned(
                top: _animation.value * (widget.size - 20),
                left: 10,
                right: 10,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.6),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final Color color;
  final double strokeWidth = 4;
  final double bracketLength = 40;

  _BracketPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    path.moveTo(0, bracketLength);
    path.lineTo(0, strokeWidth / 2);
    path.quadraticBezierTo(0, 0, strokeWidth / 2, 0);
    path.lineTo(bracketLength, 0);

    path.moveTo(size.width - bracketLength, 0);
    path.lineTo(size.width - strokeWidth / 2, 0);
    path.quadraticBezierTo(
        size.width, 0, size.width, strokeWidth / 2);
    path.lineTo(size.width, bracketLength);

    path.moveTo(size.width, size.height - bracketLength);
    path.lineTo(size.width, size.height - strokeWidth / 2);
    path.quadraticBezierTo(size.width, size.height, size.width - strokeWidth / 2,
        size.height);
    path.lineTo(size.width - bracketLength, size.height);

    path.moveTo(bracketLength, size.height);
    path.lineTo(strokeWidth / 2, size.height);
    path.quadraticBezierTo(
        0, size.height, 0, size.height - strokeWidth / 2);
    path.lineTo(0, size.height - bracketLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}