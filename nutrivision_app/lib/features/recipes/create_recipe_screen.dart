import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nutrivision_app/core/services/database_helper.dart';

class CreateRecipeScreen extends StatefulWidget {
  const CreateRecipeScreen({super.key});

  @override
  State<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  final _nameController = TextEditingController();
  final List<Map<String, dynamic>> _ingredients = [];
  
  // Temporary controllers for adding ingredient
  final _ingNameController = TextEditingController();
  final _ingCalController = TextEditingController();
  final _ingProtController = TextEditingController();
  final _ingCarbController = TextEditingController();
  final _ingFatController = TextEditingController();

  void _addIngredient() {
    if (_ingNameController.text.isEmpty) return;

    setState(() {
      _ingredients.add({
        'name': _ingNameController.text,
        'calories': int.tryParse(_ingCalController.text) ?? 0,
        'protein_g': int.tryParse(_ingProtController.text) ?? 0,
        'carbs_g': int.tryParse(_ingCarbController.text) ?? 0,
        'fat_g': int.tryParse(_ingFatController.text) ?? 0,
      });
    });

    _ingNameController.clear();
    _ingCalController.clear();
    _ingProtController.clear();
    _ingCarbController.clear();
    _ingFatController.clear();
    Navigator.pop(context); // Close dialog
  }

  void _showAddIngredientDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Ingredient'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _ingNameController,
                decoration: const InputDecoration(labelText: 'Name (e.g. Oats)'),
              ),
              TextField(
                controller: _ingCalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Calories'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ingProtController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Prot (g)'),
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: TextField(
                      controller: _ingCarbController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Carb (g)'),
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: TextField(
                      controller: _ingFatController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Fat (g)'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addIngredient,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRecipe() async {
    if (_nameController.text.isEmpty || _ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a name and ingredients')),
      );
      return;
    }

    int totalCal = 0;
    int totalProt = 0;
    int totalCarb = 0;
    int totalFat = 0;

    for (var ing in _ingredients) {
      totalCal += (ing['calories'] as int);
      totalProt += (ing['protein_g'] as int);
      totalCarb += (ing['carbs_g'] as int);
      totalFat += (ing['fat_g'] as int);
    }

    final db = DatabaseHelper.instance;
    final dbInstance = await db.database;

    final recipeId = await dbInstance.insert('recipes', {
      'name': _nameController.text,
      'total_calories': totalCal,
      'total_protein': totalProt,
      'total_carbs': totalCarb,
      'total_fat': totalFat,
    });

    for (var ing in _ingredients) {
      await dbInstance.insert('recipe_ingredients', {
        'recipe_id': recipeId,
        'name': ing['name'],
        'calories': ing['calories'],
        'protein_g': ing['protein_g'],
        'carbs_g': ing['carbs_g'],
        'fat_g': ing['fat_g'],
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe Saved!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalCal = 0;
    for (var ing in _ingredients) {
      totalCal += (ing['calories'] as int);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Recipe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveRecipe,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Recipe Name',
                border: OutlineInputBorder(),
              ),
            ),
            const Gap(16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ingredients',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Total: $totalCal Cal',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
              ],
            ),
            const Gap(8),
            Expanded(
              child: ListView.separated(
                itemCount: _ingredients.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final ing = _ingredients[index];
                  return ListTile(
                    title: Text(ing['name']),
                    subtitle: Text(
                        '${ing['calories']} Cal • P: ${ing['protein_g']}g C: ${ing['carbs_g']}g F: ${ing['fat_g']}g'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _ingredients.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddIngredientDialog,
        label: const Text('Add Ingredient'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
