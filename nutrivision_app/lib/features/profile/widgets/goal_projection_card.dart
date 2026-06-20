import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class GoalProjectionCard extends StatelessWidget {
  final double currentWeight;
  final double goalWeight;
  final String goal; // 'loss', 'gain', 'maintain'

  const GoalProjectionCard({
    super.key,
    required this.currentWeight,
    required this.goalWeight,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    if (goal == 'maintain' || currentWeight == 0 || goalWeight == 0) {
      return const SizedBox.shrink(); // No projection needed
    }

    final projection = _calculateProjection();
    final arrivalDate = projection['date'] as DateTime?;
    final weeks = projection['weeks'] as int;

    if (weeks <= 0) {
      return _buildCard(
        context,
        "Goal Reached!",
        "You've hit your target weight!",
        Icons.emoji_events,
        Colors.green,
      );
    }

    final dateStr = arrivalDate != null ? DateFormat.yMMMd().format(arrivalDate) : "Soon";

    return _buildCard(
      context,
      "Estimated Arrival",
      "Reach $goalWeight kg by $dateStr",
      Icons.trending_up,
      Colors.blue,
      extra: "$weeks weeks to go at current pace",
    );
  }

  Map<String, dynamic> _calculateProjection() {
    double diff = (currentWeight - goalWeight).abs();
    double pace = 0.5; // Default kg/week

    if (goal.contains('slow')) pace = 0.25;
    if (goal.contains('fast')) pace = 0.75;
    
    int weeks = (diff / pace).ceil();
    DateTime date = DateTime.now().add(Duration(days: weeks * 7));

    return {'weeks': weeks, 'date': date};
  }

  Widget _buildCard(BuildContext context, String title, String subtitle, IconData icon, Color color, {String? extra}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))
              ]
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const Gap(20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                const Gap(4),
                Text(subtitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, height: 1.2)),
                if (extra != null) ...[
                  const Gap(4),
                  Text(extra, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ]
              ],
            ),
          )
        ],
      ),
    );
  }
}
