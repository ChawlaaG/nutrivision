import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../core/models/meal.dart';
import '../../../core/providers/meal_provider.dart';

class ManualEntryScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final Meal? meal; // Optional meal for editing

  const ManualEntryScreen({super.key, required this.imagePath, this.meal});

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;

  late String _selectedMealType;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void initState() {
    super.initState();
    final meal = widget.meal;
    _nameController = TextEditingController(text: meal?.name ?? '');
    _caloriesController = TextEditingController(text: meal?.calories.toString() ?? '');
    _proteinController = TextEditingController(text: meal?.protein.toString() ?? '');
    _carbsController = TextEditingController(text: meal?.carbs.toString() ?? '');
    _fatController = TextEditingController(text: meal?.fat.toString() ?? '');

    _selectedMealType = meal?.mealType ?? 'Breakfast';
    _selectedDate = meal?.timestamp ?? DateTime.now();
    _selectedTime = meal != null ? TimeOfDay.fromDateTime(meal.timestamp) : TimeOfDay.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveMeal() async {
    if (_formKey.currentState!.validate()) {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final meal = Meal(
        id: widget.meal?.id, // Preserve ID if editing
        name: _nameController.text,
        calories: int.parse(_caloriesController.text),
        protein: int.parse(_proteinController.text),
        carbs: int.parse(_carbsController.text),
        fat: int.parse(_fatController.text),
        timestamp: dateTime,
        mealType: _selectedMealType,
        imagePath: widget.imagePath,
      );

      if (widget.meal != null) {
        await ref.read(mealControllerProvider.notifier).updateMeal(meal);
      } else {
        await ref.read(mealControllerProvider.notifier).addMeal(meal);
      }

      if (mounted) {
        Navigator.pop(context); // Return to Scanner/Dashboard
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.meal != null ? 'Meal updated successfully!' : 'Meal added successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.meal != null ? 'Edit Meal' : 'Add Meal Manually'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meal Type Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedMealType,
                decoration: _inputDecoration('Meal Type'),
                items: _mealTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedMealType = newValue!;
                  });
                },
              ),
              const Gap(16),

              // Date & Time Pickers
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: _inputDecoration('Date'),
                        child: Text(
                          DateFormat('MMM d, y').format(_selectedDate),
                        ),
                      ),
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      child: InputDecorator(
                        decoration: _inputDecoration('Time'),
                        child: Text(
                          _selectedTime.format(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(24),

              // Food Name
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Food Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter food name';
                  }
                  return null;
                },
              ),
              const Gap(16),

              // Calories
              TextFormField(
                controller: _caloriesController,
                decoration: _inputDecoration('Calories'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const Gap(16),

              // Macros
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _proteinController,
                      decoration: _inputDecoration('Protein (g)'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? '0' : null, // Default to 0 if empty?
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: TextFormField(
                      controller: _carbsController,
                      decoration: _inputDecoration('Carbs (g)'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? '0' : null,
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: TextFormField(
                      controller: _fatController,
                      decoration: _inputDecoration('Fat (g)'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? '0' : null,
                    ),
                  ),
                ],
              ),
              const Gap(32),

              // Save Button
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
                  child: Text(
                    widget.meal != null ? 'Update Meal' : 'Save Meal',
                    style: const TextStyle(
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
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.black, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
}
