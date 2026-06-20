import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/models/meal.dart';
import '../../../core/providers/meal_provider.dart';

class FoodDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> foodData;
  final String imagePath;

  const FoodDetailScreen({
    super.key, 
    required this.foodData,
    required this.imagePath,
  });

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  double _quantity = 1.0;
  final TextEditingController _qtyController = TextEditingController(text: '1.0');
  String _selectedMealType = 'Breakfast';
  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  int get _totalCalories => (widget.foodData['calories'] * _quantity).round();
  int get _totalProtein => (widget.foodData['protein'] * _quantity).round();
  int get _totalCarbs => (widget.foodData['carbs'] * _quantity).round();
  int get _totalFat => (widget.foodData['fat'] * _quantity).round();

  Future<void> _saveMeal() async {
    final meal = Meal(
      name: widget.foodData['name'],
      calories: _totalCalories,
      protein: _totalProtein,
      carbs: _totalCarbs,
      fat: _totalFat,
      timestamp: DateTime.now(),
      mealType: _selectedMealType,
      imagePath: widget.imagePath,
    );

    await ref.read(mealControllerProvider.notifier).addMeal(meal);

    if (mounted) {
      // Pop back to Dashboard
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal added successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.foodData['name']),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Calories',
                          style: TextStyle(color: Colors.green, fontSize: 16)),
                      Text(
                        '$_totalCalories Cal',
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_fire_department,
                        color: Colors.orange, size: 32),
                  ),
                ],
              ),
            ),
            const Gap(32),

            // Quantity Selector
            const Text('Quantity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Gap(16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _qtyController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '1.0',
                            ),
                            onChanged: (val) {
                              final parsed = double.tryParse(val);
                              if (parsed != null && parsed > 0) {
                                setState(() => _quantity = parsed);
                              }
                            },
                          ),
                        ),
                        Text(widget.foodData['unit'] ?? 'serving',
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Gap(24),

            // Meal Type Selector
            const Text('Meal Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Gap(16),
            Wrap(
              spacing: 12,
              children: _mealTypes.map((type) {
                final isSelected = _selectedMealType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedMealType = type);
                  },
                  selectedColor: Colors.black,
                  labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black),
                  backgroundColor: Colors.grey[100],
                );
              }).toList(),
            ),
            const Gap(32),

            // Macros Breakdown
            const Text('Macronutrients Breakdown',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Gap(16),
            _buildMacroRow('Protein', '$_totalProtein g'),
            _buildMacroRow('Carbs', '$_totalCarbs g'),
            _buildMacroRow('Fats', '$_totalFat g'),

            const Spacer(),

            // Add Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveMeal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'ADD TO LOG',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
