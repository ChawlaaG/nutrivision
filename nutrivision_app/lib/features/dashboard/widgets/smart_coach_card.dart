import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class SmartCoachCard extends StatelessWidget {
  final Map<String, int> macros; // Consumed
  final Map<String, int> goals;  // Goals (can be estimated or passed)
  final int consumedCalories;
  final int calorieGoal;

  const SmartCoachCard({
    super.key,
    required this.macros,
    required this.consumedCalories,
    required this.calorieGoal,
    // We'll estimate macro goals if not provided, or usage context can pass them
    this.goals = const {}, 
  });

  @override
  Widget build(BuildContext context) {
    // 1. Determine the "Tip"
    final tip = _generateTip();

    // 2. Render Card
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey[900]!, Colors.blueGrey[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              tip['icon']!,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Smart Coach",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                const Gap(4),
                Text(
                  tip['text']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _generateTip() {
    final now = DateTime.now();
    final hour = now.hour;
    
    // Safety check div by zero
    if (calorieGoal == 0) return {'icon': '👋', 'text': "Set your goals to get smart tips!"};

    final pct = consumedCalories / calorieGoal;

    // Morning (5AM - 11AM)
    if (hour >= 5 && hour < 11) {
      if (consumedCalories == 0) return {'icon': '🌅', 'text': "Good morning! Start with water and a protein-rich breakfast."};
      if (pct > 0.4) return {'icon': '⚠️', 'text': "Big breakfast! Keep it light for lunch."};
      return {'icon': '☕', 'text': "You're off to a great start. Stay hydrated!"};
    }

    // Mid-Day (11AM - 4PM)
    if (hour >= 11 && hour < 16) {
      if (pct < 0.2) return {'icon': '🔋', 'text': "Fuel up! Don't skip lunch."};
      // Check Protein (simplified goal check: assume 30% calories is protein ~ 1g/4kcal? 
      // Let's use raw val. If protein < 20g by noon?)
      final protein = macros['protein'] ?? 0;
      if (protein < 30) return {'icon': '💪', 'text': "Protein check: Try adding chicken or tofu to your lunch."};
      return {'icon': '🥗', 'text': "Keep your energy steady with fiber and greens."};
    }

    // Evening (4PM - 9PM)
    if (hour >= 16 && hour < 21) {
      if (pct > 0.9) return {'icon': '🛑', 'text': "You're close to your limit. Opt for a light dinner."};
      if (pct < 0.5) return {'icon': '🍽️', 'text': "Plenty of calories left. Treat yourself to a hearty dinner!"};
      
      final carbs = macros['carbs'] ?? 0;
      // If carbs dominant?
      if (carbs > 200) return {'icon': '🍞', 'text': "Carbs are high today. Maybe veggies for dinner?"};
      return {'icon': '🌙', 'text': "Winding down? Avoid caffeine and heavy sugar."};
    }

    // Late Night
    if (pct > 1.0) return {'icon': '🚫', 'text': "Goal exceeded. Drink water and rest well."};
    return {'icon': '💤', 'text': "Time to rest. Recovery is key to progress."};
  }
}
