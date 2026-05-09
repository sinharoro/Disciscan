import 'package:flutter/material.dart';
import '../theme.dart';

class CountdownBar extends StatefulWidget {
  final int durationSeconds;
  final VoidCallback onComplete;
  final VoidCallback? onDismiss;

  const CountdownBar({
    super.key,
    this.durationSeconds = 4,
    required this.onComplete,
    this.onDismiss,
  });

  @override
  State<CountdownBar> createState() => _CountdownBarState();
}

class _CountdownBarState extends State<CountdownBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: widget.durationSeconds),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void dismiss() {
    _controller.stop();
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 1 - _animation.value,
                    backgroundColor: AppColors.darkCard,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.textSecondary.withOpacity(0.5),
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Returning in ${((1 - _animation.value) * widget.durationSeconds).ceil()}s...',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: dismiss,
          child: const Text('Next scan'),
        ),
      ],
    );
  }
}