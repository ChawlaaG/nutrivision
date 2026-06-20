import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nutrivision_app/core/services/health_service.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class StepsCard extends StatefulWidget {
  const StepsCard({super.key});

  @override
  State<StepsCard> createState() => _StepsCardState();
}

class _StepsCardState extends State<StepsCard> {
  int _steps = 0;
  int _caloriesBurned = 0;
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _initHealth();
  }

  Future<void> _initHealth() async {
    final healthService = HealthService();
    final authorized = await healthService.requestPermissions();
    
    if (mounted) {
      setState(() {
        _hasPermission = authorized;
      });
    }

    if (authorized) {
      final steps = await healthService.getTodaySteps();
      final calories = await healthService.getTodayBurnedCalories();
      if (mounted) {
        setState(() {
          _steps = steps;
          _caloriesBurned = calories;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const int stepGoal = 10000;
    final double percent = (_steps / stepGoal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.directions_walk, color: Colors.orange, size: 20),
                  Gap(8),
                  Text(
                    'Activity',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (!_hasPermission && !_isLoading)
                TextButton(
                  onPressed: _initHealth,
                  child: const Text('Sync', style: TextStyle(color: Colors.blue)),
                ),
            ],
          ),
          const Gap(16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (!_hasPermission)
             const Text(
              'Sync with Health Connect to track steps.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            )
          else
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_steps',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Steps',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$_caloriesBurned kcal',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Burned',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const Gap(12),
                LinearPercentIndicator(
                  lineHeight: 8.0,
                  percent: percent,
                  backgroundColor: Colors.grey[800],
                  progressColor: Colors.orange,
                  barRadius: const Radius.circular(4),
                  padding: EdgeInsets.zero,
                  animation: true,
                ),
                const Gap(4),
                const Text(
                  'Goal: $stepGoal steps',
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
