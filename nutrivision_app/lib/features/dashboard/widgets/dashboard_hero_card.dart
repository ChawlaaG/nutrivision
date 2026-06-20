import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class DashboardHeroCard extends StatelessWidget {
  final int caloriesLeft;
  final int calorieGoal;
  final int caloriesBurned; // Optional, for the fire icon context if needed

  const DashboardHeroCard({
    super.key,
    required this.caloriesLeft,
    required this.calorieGoal,
    this.caloriesBurned = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate progress (inverse logic: if 1653 left of 2000, progress is (2000-1653)/2000)
    // Actually, usually "Left" implies we start full and go down, OR we fill up "Eaten".
    // The screenshot shows a ring. Let's assume the ring fills up as we eat.
    // If "Calories Left" is the big number, the ring likely represents "Calories Eaten".
    final caloriesEaten = calorieGoal - caloriesLeft;
    final double progress = (caloriesEaten / calorieGoal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$caloriesLeft',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Calories ',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(
                      text: 'left',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          CircularPercentIndicator(
            radius: 40.0,
            lineWidth: 8.0,
            percent: progress,
            center: const Icon(Icons.local_fire_department_rounded,
                color: Colors.black, size: 32),
            backgroundColor: Colors.grey[100]!,
            progressColor:
                Colors.black, // Or a gradient if we want to be fancy later
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
          ),
        ],
      ),
    );
  }
}
