import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AROverlay extends StatelessWidget {
  final List<dynamic> items;
  final Function(dynamic item) onItemTap;

  const AROverlay({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: items.map((item) {
        final coords = item['box_2d'] as List;
        final x = coords[0] as num;
        final y = coords[1] as num;

        return Positioned(
          left: (x / 100) * MediaQuery.of(context).size.width,
          top: (y / 100) * MediaQuery.of(context).size.width, // Assuming square aspect ratio for now
          child: GestureDetector(
            onTap: () => onItemTap(item),
            child: const PulsingDot(),
          ),
        );
      }).toList(),
    );
  }
}

class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _animation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 24 * _animation.value,
          height: 24 * _animation.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 1.0 - (_animation.value - 0.5)),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}
