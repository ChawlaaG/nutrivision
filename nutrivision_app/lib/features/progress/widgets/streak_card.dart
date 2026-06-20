import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class StreakCard extends StatelessWidget {
  final int streakDays;

  const StreakCard({super.key, required this.streakDays});

  @override
  Widget build(BuildContext context) {
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Fire Icon (Using generic for now, ideally SVG or custom asset)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.orange,
              size: 36,
            ),
          ),
          const Gap(8),
          Text(
            '$streakDays',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const Text(
            'Day streak',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const Gap(16),
          // Weekly Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              // 0 is 6 days ago, 6 is today
              int daysAgo = 6 - index;
              bool isActive = daysAgo < streakDays;
              DateTime date = DateTime.now().subtract(Duration(days: daysAgo));
              String dayName = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][date.weekday - 1];

              return Column(
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? Colors.orange : Colors.grey[300],
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
