import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class WeightCard extends StatelessWidget {
  final double currentWeight;
  final double goalWeight;
  final double startWeight; // Needed to calculate progress percentage

  const WeightCard({
    super.key,
    required this.currentWeight,
    required this.goalWeight,
    required this.startWeight,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate progress: 0.0 to 1.0
    // If losing weight: (start - current) / (start - goal)
    // If gaining weight: (current - start) / (goal - start)
    double progress = 0.0;
    if (startWeight > goalWeight) {
      progress = (startWeight - currentWeight) / (startWeight - goalWeight);
    } else if (startWeight < goalWeight) {
      progress = (currentWeight - startWeight) / (goalWeight - startWeight);
    }
    progress = progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Text(
            'My Weight',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                currentWeight.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'kg',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const Gap(16),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[100],
              color: Colors.black, // Or primary color
              minHeight: 8,
            ),
          ),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Goal ',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              Text(
                '${goalWeight.toStringAsFixed(1)} kg',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Gap(16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Next weight-in: 6d', // Static for now
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
