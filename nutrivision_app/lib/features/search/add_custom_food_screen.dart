import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../core/repositories/food_repository.dart';

class AddCustomFoodScreen extends StatefulWidget {
  const AddCustomFoodScreen({super.key});

  @override
  State<AddCustomFoodScreen> createState() => _AddCustomFoodScreenState();
}

class _AddCustomFoodScreenState extends State<AddCustomFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = FoodRepository();
  
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _servingController = TextEditingController(text: '1 serving');

  bool _isSaving = false;

  Future<void> _saveFood() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _repository.addCustomFood(
        name: _nameController.text,
        calories: int.parse(_caloriesController.text),
        protein: int.parse(_proteinController.text),
        carbs: int.parse(_carbsController.text),
        fat: int.parse(_fatController.text),
        servingSize: _servingController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Food created successfully!')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating food: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('Create Custom Food'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Food Details'),
              const Gap(16),
              _buildTextField(
                controller: _nameController,
                label: 'Food Name',
                hint: 'e.g., Homemade Burger',
                icon: Icons.fastfood,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const Gap(16),
              _buildTextField(
                controller: _servingController,
                label: 'Serving Size',
                hint: 'e.g., 1 burger (200g)',
                icon: Icons.scale,
              ),
              const Gap(32),
              _buildSectionTitle('Nutrition Facts'),
              const Gap(16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _caloriesController,
                      label: 'Calories',
                      suffix: 'kcal',
                      isNumber: true,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: _buildTextField(
                      controller: _proteinController,
                      label: 'Protein',
                      suffix: 'g',
                      isNumber: true,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const Gap(16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _carbsController,
                      label: 'Carbs',
                      suffix: 'g',
                      isNumber: true,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: _buildTextField(
                      controller: _fatController,
                      label: 'Fat',
                      suffix: 'g',
                      isNumber: true,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const Gap(40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveFood,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Food',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? suffix,
    IconData? icon,
    bool isNumber = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
