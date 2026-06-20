import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class MacroCard extends StatelessWidget {
  final String label;
  final int amountLeft;
  final int totalAmount;
  final IconData icon;
  final Color color; // Used for the icon background/tint if needed

  const MacroCard({
    super.key,
    required this.label,
    required this.amountLeft,
    required this.totalAmount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final amountEaten = totalAmount - amountLeft;
    final double progress = (amountEaten / totalAmount).clamp(0.0, 1.0);

    return Container(
      width: 110, // Fixed width for horizontal scrolling or grid
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${amountLeft}g',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const TextSpan(
                  text: 'left',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: CircularPercentIndicator(
              radius: 24.0,
              lineWidth: 4.0,
              percent: progress,
              center: Icon(icon, color: color, size: 20),
              backgroundColor: Colors.grey[100]!,
              progressColor: color.withValues(alpha: 0.3), // Subtle color ring
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
            ),
          ),
        ],
      ),
    );
  }
}
