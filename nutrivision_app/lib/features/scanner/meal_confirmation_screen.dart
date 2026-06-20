import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/services/ai_service.dart';
import '../../../core/models/meal.dart';
import '../../../core/providers/meal_provider.dart';
import 'models/scanned_food_item.dart';

class MealConfirmationScreen extends ConsumerStatefulWidget {
  final String imagePath;

  const MealConfirmationScreen({super.key, required this.imagePath});

  @override
  ConsumerState<MealConfirmationScreen> createState() => _MealConfirmationScreenState();
}

class _MealConfirmationScreenState extends ConsumerState<MealConfirmationScreen> {
  final _aiService = AIService();
  bool _isLoading = true;

  // List of detected/added items
  List<ScannedFoodItem> _items = [];
  
  // Controller for the meal name (e.g., "Lunch", "South Indian Platter")
  final _mealNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    try {
      final result = await _aiService.analyzeFoodImage(widget.imagePath);
      
      if (mounted) {
        setState(() {
          final summary = result['summary'] ?? {};
          _mealNameController.text = summary['title'] ?? 'My Meal';

          final itemsJson = result['items'] as List<dynamic>? ?? [];
          _items = itemsJson.map((item) {
            final macros = item['macros'] ?? {};
            return ScannedFoodItem(
              name: item['name']?.toString() ?? 'Unknown Item',
              caloriesPerUnit: (item['calories'] as num?)?.toInt() ?? 0,
              proteinPerUnit: (macros['p'] as num?)?.toInt() ?? 0,
              carbsPerUnit: (macros['c'] as num?)?.toInt() ?? 0,
              fatPerUnit: (macros['f'] as num?)?.toInt() ?? 0,
              quantity: 1.0, // Default quantity
            );
          }).toList();
          
          // If no items detected but summary exists, create a generic item
          if (_items.isEmpty) {
             final macros = result['macros'] ?? {};
             _items.add(ScannedFoodItem(
               name: 'Total Meal',
               caloriesPerUnit: (summary['total_calories'] as num?)?.toInt() ?? 0,
               proteinPerUnit: (macros['protein_g'] as num?)?.toInt() ?? 0,
               carbsPerUnit: (macros['carbs_g'] as num?)?.toInt() ?? 0,
               fatPerUnit: (macros['fats_g'] as num?)?.toInt() ?? 0,
             ));
          }
                  _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('AI Analysis Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        
        if (errorMessage.contains('Invalid API Key')) {
          _showApiKeyDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $errorMessage'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 10),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  setState(() => _isLoading = true);
                  _analyzeImage();
                },
              ),
            ),
          );
        }
      }
    }
  }

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Missing API Key'),
        content: const Text(
          'To use the AI Food Scanner, you need a valid Gemini API Key.\n\n'
          '1. Get a key at aistudio.google.com\n'
          '2. Add it to lib/core/constants/secrets.dart',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // --- Logic for Totals ---
  int get _totalCalories => _items.fold(0, (sum, item) => sum + item.totalCalories);
  int get _totalProtein => _items.fold(0, (sum, item) => sum + item.totalProtein);
  int get _totalCarbs => _items.fold(0, (sum, item) => sum + item.totalCarbs);
  int get _totalFat => _items.fold(0, (sum, item) => sum + item.totalFat);

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) => _AddManualItemDialog(
        onAdd: (newItem) {
          setState(() {
            _items.add(newItem);
          });
        },
      ),
    );
  }

  Future<void> _saveMeal() async {
    if (_mealNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a meal name')),
      );
      return;
    }

    final meal = Meal(
      name: _mealNameController.text,
      calories: _totalCalories,
      protein: _totalProtein,
      carbs: _totalCarbs,
      fat: _totalFat,
      imagePath: widget.imagePath,
      timestamp: DateTime.now(),
    );

    await ref.read(mealControllerProvider.notifier).addMeal(meal);

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: _FoodProcessingView(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Meal'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(
                      File(widget.imagePath),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Gap(20),

                  // Meal Name Input
                  TextField(
                    controller: _mealNameController,
                    decoration: InputDecoration(
                      labelText: 'Meal Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const Gap(20),

                  // Items List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Detected Items',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Item'),
                      ),
                    ],
                  ),
                  const Gap(10),

                  // Items List
                  if (_items.isEmpty)
                    const Center(child: Text('No items detected. Add one manually!'))
                  else
                    ..._items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return _buildItemCard(item, index);
                    }),
                  
                  const Gap(100), // Space for bottom sheet
                ],
              ),
            ),
          ),
          
          // Bottom Summary Sheet
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem('Calories', '$_totalCalories', Colors.orange),
                      _buildSummaryItem('Protein', '${_totalProtein}g', Colors.blue),
                      _buildSummaryItem('Carbs', '${_totalCarbs}g', Colors.green),
                      _buildSummaryItem('Fat', '${_totalFat}g', Colors.red),
                    ],
                  ),
                  const Gap(20),
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
                        'Add to Log',
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
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(ScannedFoodItem item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${item.caloriesPerUnit} cal/unit',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Quantity Controls
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: () {
                          setState(() {
                            if (item.quantity > 0.5) {
                              item.quantity -= 0.5;
                            } else {
                              _items.removeAt(index);
                            }
                          });
                        },
                      ),
                      Text(
                        item.quantity.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: () {
                          setState(() {
                            item.quantity += 0.5;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: ${item.totalCalories} cal', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('P: ${item.totalProtein}g  C: ${item.totalCarbs}g  F: ${item.totalFat}g', 
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

// Dialog for adding manual items with AI
class _AddManualItemDialog extends StatefulWidget {
  final Function(ScannedFoodItem) onAdd;

  const _AddManualItemDialog({required this.onAdd});

  @override
  State<_AddManualItemDialog> createState() => _AddManualItemDialogState();
}

class _AddManualItemDialogState extends State<_AddManualItemDialog> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _aiService = AIService();
  bool _isLoading = false;

  Future<void> _analyzeAndAdd() async {
    if (_nameController.text.isEmpty || _quantityController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final result = await _aiService.getNutritionFromText(
        _nameController.text,
        _quantityController.text,
      );

      final item = ScannedFoodItem(
        name: _nameController.text,
        caloriesPerUnit: (result['calories'] as num?)?.toInt() ?? 0,
        proteinPerUnit: (result['protein_g'] as num?)?.toInt() ?? 0,
        carbsPerUnit: (result['carbs_g'] as num?)?.toInt() ?? 0,
        fatPerUnit: (result['fats_g'] as num?)?.toInt() ?? 0,
        quantity: 1.0, // AI accounts for quantity in the unit values
      );

      widget.onAdd(item);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to estimate: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Item (AI Powered)'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the food name and quantity, and AI will calculate the macros for you.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Gap(16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Food Name',
                hintText: 'e.g., Banana, Samosa',
                border: OutlineInputBorder(),
              ),
            ),
            const Gap(12),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                hintText: 'e.g., 1 medium, 2 pieces, 100g',
                border: OutlineInputBorder(),
              ),
            ),
            if (_isLoading) ...[
              const Gap(20),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _analyzeAndAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          child: const Text('Calculate & Add'),
        ),
      ],
    );
  }
}

// Local widget for Food Analysis animation (unchanged)
class _FoodProcessingView extends StatefulWidget {
  @override
  State<_FoodProcessingView> createState() => _FoodProcessingViewState();
}

class _FoodProcessingViewState extends State<_FoodProcessingView> {
  int _progress = 0;
  int _currentStep = 0;
  Timer? _timer;

  final List<String> _steps = [
    'Scanning image...',
    'Identifying ingredients...',
    'Calculating macros...',
    'Verifying nutritional data...',
  ];

  @override
  void initState() {
    super.initState();
    _startProcessing();
  }

  void _startProcessing() {
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_progress >= 99) {
        timer.cancel();
      } else {
        setState(() {
          _progress++;
          if (_progress < 30) {
            _currentStep = 0;
          } else if (_progress < 60) {
            _currentStep = 1;
          } else if (_progress < 90) {
            _currentStep = 2;
          } else {
            _currentStep = 3;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$_progress%',
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: -2,
              ),
            ),
            const Gap(40),
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.grey[200],
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progress / 100,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: const LinearGradient(
                      colors: [Colors.black, Colors.grey],
                    ),
                  ),
                ),
              ),
            ),
            const Gap(60),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: List.generate(_steps.length, (index) {
                  final isCompleted = index < _currentStep;
                  final isCurrent = index == _currentStep;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? Colors.green
                                : (isCurrent ? Colors.black : Colors.grey[200]),
                          ),
                          child: isCompleted
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : (isCurrent
                                  ? const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null),
                        ),
                        const Gap(16),
                        Text(
                          _steps[index],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                isCurrent ? FontWeight.bold : FontWeight.w500,
                            color: isCurrent ? Colors.black : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
