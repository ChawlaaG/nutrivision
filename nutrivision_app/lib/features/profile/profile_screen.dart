import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/profile_service.dart';
import 'widgets/goal_projection_card.dart';
import '../reports/weekly_progress_screen.dart';
import '../welcome/welcome_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _profileService = ProfileService();

  Map<String, dynamic> _userProfile = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await _profileService.getUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _profileService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    double? weight = (_userProfile['weight'] as num?)?.toDouble();
    double? height = (_userProfile['height'] as num?)?.toDouble();
    int? age = (_userProfile['age'] as num?)?.toInt();
    
    // Calculate BMI
    String bmiDisplay = "--";
    if (weight != null && height != null) {
       double heightInMeters = height / 100;
       double bmi = weight / (heightInMeters * heightInMeters);
       bmiDisplay = bmi.toStringAsFixed(1);
    }
    
    String goalWeight = "Not Set";
    if (weight != null) {
      if (_userProfile['goal'] == 'loss') {
        goalWeight = "${(weight - 5).toStringAsFixed(1)} kg";
      } else if (_userProfile['goal'] == 'gain') { goalWeight = "${(weight + 5).toStringAsFixed(1)} kg"; }
      else { goalWeight = "${weight.toStringAsFixed(1)} kg"; } // Maintain
    }

    // Calculate Target Weight for Projection
    double targetWeightVal = weight ?? 0;
    if (weight != null) {
      if (_userProfile['goal'] == 'loss') {
        targetWeightVal = weight - 5;
      } else if (_userProfile['goal'] == 'gain') { targetWeightVal = weight + 5; }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(_userProfile['name'] ?? 'Profile'),
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          ValueListenableBuilder<SyncStatus>(
            valueListenable: _profileService.syncStatus,
            builder: (context, status, child) {
              switch (status) {
                case SyncStatus.synced:
                  return IconButton(
                    icon: const Icon(Icons.cloud_done, color: Colors.green),
                    onPressed: () => _showSyncDialog(context, "Synced", "Your data is safely backed up to the cloud."),
                  );
                case SyncStatus.syncing:
                  return const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                    ),
                  );
                case SyncStatus.error:
                  return IconButton(
                    icon: const Icon(Icons.cloud_off, color: Colors.red),
                    onPressed: () => _profileService.syncProfile(), // Retry
                  );
                 case SyncStatus.pending:
                   return IconButton(
                    icon: const Icon(Icons.cloud_upload, color: Colors.orange),
                    tooltip: "Sync Pending",
                    onPressed: () => _profileService.syncProfile(),
                  );
              }
            },
          ),
          const Gap(8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Top Stats Card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1E35), // Dark Blue
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(weight != null ? "${weight.toStringAsFixed(1)} kg" : "--", "Current Weight"),
                  _buildStatItem(goalWeight, "Goal Weight"),
                  _buildStatItem(bmiDisplay, "Current BMI"),
                ],
              ),
            ),
            const Gap(24),

            // Goal Projection
            if (weight != null)
              GoalProjectionCard(
                currentWeight: weight,
                goalWeight: targetWeightVal,
                goal: _userProfile['goal'] ?? 'maintain',
              ),
            const Gap(24),

            // Upsell Banner (Placeholder)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue[50]!, Colors.white]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Unlimited access to AI identifier", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Gap(8),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A1E35),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text("Claim Now", style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                  ),
                   // Placeholder icon
                   Container(
                     height: 60, width: 60,
                     decoration: const BoxDecoration(
                       color: Colors.orange,
                       shape: BoxShape.circle,
                     ),
                     child: const Icon(Icons.star, color: Colors.white, size: 30),
                   )
                ],
              ),
            ),
            const Gap(32),

            // Help & Feedback Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.orange),
                label: const Text("Help & Feedback", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.orange),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            const Gap(32),

            // Profile Section
            _buildSectionTitle("PROFILE"),
            _buildMenuContainer([
              _buildMenuTile("Age", age != null ? "$age" : "Not Set", onTap: () => _showEditDialog("Age", "age", age?.toString() ?? "")),
              _buildMenuTile("Gender", "${_userProfile['gender'] ?? 'N/A'}", onTap: () {
                _showSelectionDialog("Gender", "gender", ["male", "female", "other"], _userProfile['gender']);
              }),
              _buildMenuTile("Height", height != null ? "$height cm" : "Not Set", onTap: () => _showEditDialog("Height", "height", height?.toString() ?? "")),
              _buildMenuTile("Weight", weight != null ? "$weight kg" : "Not Set", onTap: () => _showEditDialog("Weight", "weight", weight?.toString() ?? "")),
              _buildMenuTile("Goal", _userProfile['goal'] ?? "Not Set", onTap: () => _showSelectionDialog("Goal", "goal", ["loss", "maintain", "gain"], _userProfile['goal'])),
            ]),
            const Gap(24),

            // Analytics Section
            _buildSectionTitle("ANALYTICS"),
            _buildMenuContainer([
              _buildMenuTile(
                "Weekly Progress", 
                "View Report", 
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WeeklyProgressScreen()))
              ),
            ]),
            const Gap(24),

            // Lifestyle Section
            _buildSectionTitle("LIFESTYLE"),
             _buildMenuContainer([
              _buildMenuTile(
                "Diet", 
                _userProfile['diet_history'] == true ? "Restricted" : "None", 
                onTap: () => _showBooleanDialog("Diet History", "diet_history", _userProfile['diet_history'] as bool?)
              ),
              _buildMenuTile(
                "Lifestyle", 
                _userProfile['lifestyle'] ?? "Sedentary", 
                onTap: () => _showSelectionDialog("Lifestyle", "lifestyle", ["Sedentary", "Lightly Active", "Moderately Active", "Very Active"], _userProfile['lifestyle'])
              ), 
              _buildMenuTile(
                "Medical Conditions", 
                _userProfile['medical_conditions'] ?? "None", 
                onTap: () => _showEditDialog("Conditions", "medical_conditions", _userProfile['medical_conditions'] ?? "")
              ),
            ]),
            const Gap(24),
            
             // Notifications Section
            _buildSectionTitle("NOTIFICATIONS"),
             _buildMenuContainer([
              _buildMenuTile("Food Log Reminder", "", isToggle: true),
            ]),
            const Gap(24),

             // General Section
            _buildSectionTitle("GENERAL"),
             _buildMenuContainer([
              _buildMenuTile("Language", "English"),
            ]),
            const Gap(24),

             // About Section
            _buildSectionTitle("ABOUT"),
             _buildMenuContainer([
              _buildMenuTile("Privacy Policy", ""),
              _buildMenuTile("Terms of Services", ""),
              _buildMenuTile("Source of Recommendations", ""),
            ]),
            const Gap(32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50], // Light red background
                  foregroundColor: Colors.red,
                  elevation: 0,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Log Out", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const Gap(16),
            TextButton(
              onPressed: _deleteAccount,
              child: Text("Delete Account", style: TextStyle(color: Colors.grey[400])),
            ),
            const Gap(40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const Gap(4),
        Text(label, style: TextStyle(color: Colors.blue[100], fontSize: 10)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title, 
        style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildMenuContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildMenuTile(String title, String value, {bool isToggle = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            if (isToggle)
               const Icon(Icons.toggle_on, color: Colors.green, size: 30)
            else
               Row(
                 children: [
                   Text(value, style: const TextStyle(color: Colors.grey)),
                   const Gap(8),
                   const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                 ],
               )
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to delete your account? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await _profileService.clearProfile(); // Assuming this method exists or I'll create it
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showEditDialog(String title, String key, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit $title"),
        content: TextField(
          controller: controller,
          keyboardType: (key == 'height' || key == 'weight' || key == 'age') 
              ? TextInputType.number 
              : TextInputType.text,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              // Update local state first
              setState(() {
                _userProfile[key] = controller.text;
              });
              
              await _saveProfile();
              if (mounted) nav.pop();
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  void _showSelectionDialog(String title, String key, List<String> options, String? current) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Select $title"),
        content: RadioGroup<String>(
          groupValue: current,
          onChanged: (val) async {
            if (val != null) {
              final nav = Navigator.of(context);
              setState(() => _userProfile[key] = val);
              await _saveProfile();
              if (mounted) nav.pop();
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) => ListTile(
              title: Text(option),
              leading: Radio<String>(
                value: option,
              ),
              onTap: () async {
                final nav = Navigator.of(context);
                setState(() => _userProfile[key] = option);
                await _saveProfile();
                if (mounted) nav.pop();
              },
            )).toList(),
          ),
        ),
      ),
    );
  }
  
  void _showBooleanDialog(String title, String key, bool? current) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text("Do you have a restricted diet history?"),
        actions: [
          TextButton(
            onPressed: () async {
               final nav = Navigator.of(context);
               setState(() => _userProfile[key] = false);
               await _saveProfile();
               if (mounted) nav.pop();
            },
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () async {
               final nav = Navigator.of(context);
               setState(() => _userProfile[key] = true);
               await _saveProfile();
               if (mounted) nav.pop();
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    // robust parsing
    double? parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }
    int? parseInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    await _profileService.saveUserProfile(
      name: _userProfile['name'] ?? 'User',
      height: parseDouble(_userProfile['height']),
      weight: parseDouble(_userProfile['weight']),
      age: parseInt(_userProfile['age']),
      gender: _userProfile['gender'] ?? 'male',
      goal: _userProfile['goal'] ?? 'maintain',
      nutritionKnowledge: _userProfile['nutrition_knowledge'] as String?,
      dietHistory: _userProfile['diet_history'] is bool ? _userProfile['diet_history'] : null, // Handle type safety
      foodLabelKnowledge: _userProfile['food_label_knowledge'] as String?,
      trackingHistory: _userProfile['tracking_history'] as String?,
      lifestyle: _userProfile['lifestyle'] as String?,
      medicalConditions: _userProfile['medical_conditions'] as String?,
    );
  }
  void _showSyncDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }
}
