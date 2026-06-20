import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/services/database_service.dart';

class MealDetailScreen extends StatelessWidget {
  final Map<String, dynamic> meal;

  const MealDetailScreen({super.key, required this.meal});

  Future<void> _deleteMeal(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal?'),
        content: const Text('This will remove the meal from your daily log.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService().delete('meals', 'id = ?', [meal['id']]);
      if (context.mounted) {
        Navigator.pop(context, true); // Return true to indicate deletion
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final calories = meal['calories'] as int;
    final protein = meal['protein'] as int;
    final carbs = meal['carbs'] as int;
    final fat = meal['fat'] as int;
    final imagePath = meal['image_path'] as String?;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                meal['name'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
                ),
              ),
              background: imagePath != null && imagePath.isNotEmpty
                  ? Image.network(
                      imagePath, // Assuming URL for now, handle local file if needed
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.restaurant, size: 100, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: Colors.orange,
                      child: const Icon(Icons.restaurant, size: 100, color: Colors.white),
                    ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteMeal(context),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Macro Chart
                  SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: protein.toDouble(),
                                  color: Colors.blue,
                                  title: 'P',
                                  radius: 50,
                                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                PieChartSectionData(
                                  value: carbs.toDouble(),
                                  color: Colors.green,
                                  title: 'C',
                                  radius: 50,
                                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                PieChartSectionData(
                                  value: fat.toDouble(),
                                  color: Colors.orange,
                                  title: 'F',
                                  radius: 50,
                                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMacroRow('Calories', '$calories kcal', Colors.black),
                              const Gap(8),
                              _buildMacroRow('Protein', '${protein}g', Colors.blue),
                              const Gap(8),
                              _buildMacroRow('Carbs', '${carbs}g', Colors.green),
                              const Gap(8),
                              _buildMacroRow('Fat', '${fat}g', Colors.orange),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(32),

                  // Details
                  const Text(
                    'Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Gap(16),
                  _buildDetailRow(Icons.access_time, 'Time', 
                    DateTime.fromMillisecondsSinceEpoch(meal['timestamp']).toString().substring(0, 16)),
                  const Gap(16),
                  _buildDetailRow(Icons.category, 'Type', meal['meal_type'] ?? 'Snack'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const Gap(8),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey),
        const Gap(16),
        Text(label, style: const TextStyle(fontSize: 16)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
