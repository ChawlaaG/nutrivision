import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../core/services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'male';
  String _goal = 'maintain';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.getUserProfile();
    if (mounted) {
      setState(() {
        _nameController.text = profile['name'] ?? 'User';
        _heightController.text = profile['height'].toString();
        _weightController.text = profile['weight'].toString();
        _ageController.text = profile['age'].toString();
        _gender = profile['gender'];
        _goal = profile['goal'];
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      await _profileService.saveUserProfile(
        name: _nameController.text,
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        age: int.parse(_ageController.text),
        gender: _gender,
        goal: _goal,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to refresh dashboard
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('Name'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const Gap(24),

                    // Gender Selector
                    const Text('Gender',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Gap(12),
                    Row(
                      children: [
                        _buildGenderCard('male', Icons.male, 'Male'),
                        const Gap(16),
                        _buildGenderCard('female', Icons.female, 'Female'),
                      ],
                    ),
                    const Gap(24),

                    // Stats
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('Height (cm)'),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const Gap(16),
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('Weight (kg)'),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Age'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const Gap(24),

                    // Goal Selector
                    const Text('Goal',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Gap(12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _goal,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'loss_fast', child: Text('Lose Weight Fast (-0.75kg/wk)')),
                            DropdownMenuItem(value: 'loss_normal', child: Text('Lose Weight (-0.5kg/wk)')),
                            DropdownMenuItem(value: 'loss_slow', child: Text('Lose Weight Slow (-0.25kg/wk)')),
                            DropdownMenuItem(value: 'maintain', child: Text('Maintain Weight')),
                            DropdownMenuItem(value: 'gain', child: Text('Gain Muscle')),
                          ],
                          onChanged: (val) => setState(() => _goal = val!),
                        ),
                      ),
                    ),
                    const Gap(40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                      onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
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
    );
  }

  Widget _buildGenderCard(String value, IconData icon, String label) {
    final isSelected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.black : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.black, size: 32),
              const Gap(8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
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
