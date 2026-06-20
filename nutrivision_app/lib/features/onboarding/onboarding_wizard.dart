import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import '../../core/services/profile_service.dart';
import '../../core/widgets/smooth_wheel_picker.dart';
import '../../core/widgets/animated_progress_bar.dart';
import 'widgets/processing_screen.dart';

class OnboardingWizard extends StatefulWidget {
  const OnboardingWizard({super.key});

  @override
  State<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends State<OnboardingWizard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Steps:
  // 0: Intro (Nutrient Level)
  // 1: Name
  // 2: Gender
  // 3: Age
  // 4: Height
  // 5: Weight
  // 6: Nutrition Knowledge
  // 7: Diet History (Restricted diet history)
  // 8: Food Label Knowledge
  // 9: Tracking History
  // 10: Main Goal (Lose, Maintain, Gain)
  // 11: Pace (Conditional - only if Lose/Gain)
  // 12: Processing (Always last)

  // Form Data
  String _name = '';
  String _gender = 'male';
  int _age = 25;
  int _height = 170;
  int _weight = 70;
  String _mainGoal = 'loss'; // 'loss', 'maintain', 'gain'
  double _goalSpeed = 1.0; // 0.0 (Slow), 1.0 (Normal), 2.0 (Fast)
  
  // New Data Fields
  String _nutritionKnowledge = 'Some understanding';
  bool _dietHistory = false;
  String _foodLabelKnowledge = 'Somewhat well';
  String _trackingHistory = 'Occasionally track';
  String _lifestyle = 'Sedentary';

  final _nameController = TextEditingController();
  final _conditionsController = TextEditingController(text: 'None');

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  int get _totalPages {
    // 0: Intro
    // 1: Name
    // 2: Gender
    // 3: Age
    // 4: Height
    // 5: Weight
    // 6: Nutrition Knowledge
    // 7: Diet History
    // 8: Food Label Knowledge
    // 9: Tracking History
    // 10: Lifestyle [NEW]
    // 11: Medical Conditions [NEW]
    // 12: Main Goal
    // 13: Pace (if not maintain)
    // 14: Processing
    
    // Base pages = 13 (0-12)
    // If maintain (skip pace) -> 14 total
    // If loss/gain (add pace) -> 15 total
    return _mainGoal == 'maintain' ? 14 : 15;
  }

  void _nextPage() {
    if (_currentPage == 1 && _name.isEmpty) { 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    // Goal is now index 12. If maintain, skip Pace (index 13) -> go to Processing (index 14)
    if (_currentPage == 12 && _mainGoal == 'maintain') {
      setState(() {
        _currentPage = 14;
      });
      return;
    }

    if (_currentPage < _totalPages - 1) {
      setState(() {
        _currentPage++;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      int prevPage = _currentPage - 1;
      setState(() {
        _currentPage = prevPage;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _saveAndFinish() async {
    final service = ProfileService();

    String finalGoal = _mainGoal;
    if (_mainGoal != 'maintain') {
      if (_goalSpeed < 0.5) {
        finalGoal = '${_mainGoal}_slow';
      } else if (_goalSpeed > 1.5) {
        finalGoal = '${_mainGoal}_fast';
      } else {
        finalGoal = '${_mainGoal}_normal';
      }
    }

    await service.saveUserProfile(
      name: _name,
      height: _height.toDouble(),
      weight: _weight.toDouble(),
      age: _age,
      gender: _gender,
      goal: finalGoal,
      nutritionKnowledge: _nutritionKnowledge,
      dietHistory: _dietHistory,
      foodLabelKnowledge: _foodLabelKnowledge,
      trackingHistory: _trackingHistory,
      lifestyle: _lifestyle,
      medicalConditions: _conditionsController.text.trim().isEmpty ? 'None' : _conditionsController.text.trim(),
    );

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPage == _totalPages - 1) {
      return ProcessingScreen(onComplete: _saveAndFinish);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: AnimatedProgressBar(
                progress: (_currentPage + 1) / (_totalPages - 1),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _previousPage,
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  Text(
                    'Step ${_currentPage + 1} of ${_totalPages - 1}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildIntroPage(),
                  _buildNamePage(),
                  _buildGenderPage(),
                  _buildAgePage(),
                  _buildHeightPage(),
                  _buildWeightPage(),
                  _buildNutritionKnowledgePage(),
                  _buildDietHistoryPage(),
                  _buildFoodLabelsPage(),
                  _buildTrackingHistoryPage(),
                  _buildLifestylePage(), // NEW
                  _buildMedicalConditionsPage(), // NEW
                  _buildMainGoalPage(), // Shifted
                  if (_mainGoal != 'maintain') _buildPacePage(), // Shifted
                ],
              ),
            ),

            // Next Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... [Other build methods remain same]

  Widget _buildLifestylePage() {
    return _buildPageContent(
      title: "How active are you?",
      subtitle: "This helps calculate your daily calorie needs.",
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildOptionCard('Sedentary', Icons.weekend, _lifestyle == 'Sedentary',
                () => setState(() => _lifestyle = 'Sedentary')),
            const Gap(16),
            _buildOptionCard('Lightly Active', Icons.directions_walk, _lifestyle == 'Lightly Active',
                () => setState(() => _lifestyle = 'Lightly Active')),
            const Gap(16),
            _buildOptionCard('Moderately Active', Icons.directions_run, _lifestyle == 'Moderately Active',
                () => setState(() => _lifestyle = 'Moderately Active')),
            const Gap(16),
            _buildOptionCard('Very Active', Icons.fitness_center, _lifestyle == 'Very Active',
                () => setState(() => _lifestyle = 'Very Active')),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalConditionsPage() {
    return _buildPageContent(
      title: "Any medical conditions?",
      subtitle: "Optional. List any conditions we should be aware of (e.g., Diabetes, PCOS).",
      child: Center(
        child: TextField(
          controller: _conditionsController,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(
            hintText: "Enter conditions or 'None'",
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }


  Widget _buildPageContent(
      {required String title, String? subtitle, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const Gap(8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
          const Gap(48),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildNamePage() {
    return _buildPageContent(
      title: "What's your name?",
      child: Center(
        child: TextField(
          controller: _nameController,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: "Enter your name",
            border: UnderlineInputBorder(),
          ),
          onChanged: (val) => setState(() => _name = val),
        ),
      ),
    );
  }

  Widget _buildGenderPage() {
    return _buildPageContent(
      title: "What's your gender?",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildOptionCard('Male', Icons.male, _gender == 'male',
              () => setState(() => _gender = 'male')),
          const Gap(24),
          _buildOptionCard('Female', Icons.female, _gender == 'female',
              () => setState(() => _gender = 'female')),
        ],
      ),
    );
  }

  Widget _buildAgePage() {
    return _buildPageContent(
      title: "How old are you?",
      child: Center(
        child: SmoothWheelPicker(
          minValue: 10,
          maxValue: 100,
          initialValue: _age,
          onChanged: (val) => setState(() => _age = val),
          label: "years",
        ),
      ),
    );
  }

  Widget _buildHeightPage() {
    return _buildPageContent(
      title: "How tall are you?",
      child: Center(
        child: SmoothWheelPicker(
          minValue: 100,
          maxValue: 250,
          initialValue: _height,
          onChanged: (val) => setState(() => _height = val),
          label: "cm",
        ),
      ),
    );
  }

  Widget _buildWeightPage() {
    return _buildPageContent(
      title: "What's your weight?",
      child: Center(
        child: SmoothWheelPicker(
          minValue: 30,
          maxValue: 200,
          initialValue: _weight,
          onChanged: (val) => setState(() => _weight = val),
          label: "kg",
        ),
      ),
    );
  }

  Widget _buildMainGoalPage() {
    return _buildPageContent(
      title: "What is your goal?",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildOptionCard('Lose Weight', Icons.trending_down,
              _mainGoal == 'loss', () => setState(() => _mainGoal = 'loss')),
          const Gap(16),
          _buildOptionCard(
              'Maintain Weight',
              Icons.accessibility_new,
              _mainGoal == 'maintain',
              () => setState(() => _mainGoal = 'maintain')),
          const Gap(16),
          _buildOptionCard('Gain Muscle', Icons.fitness_center,
              _mainGoal == 'gain', () => setState(() => _mainGoal = 'gain')),
        ],
      ),
    );
  }

  Widget _buildPacePage() {
    return _buildPageContent(
      title: "How fast?",
      subtitle: "This determines your daily calorie deficit/surplus.",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _getSpeedLabel(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Gap(48),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Theme.of(context).colorScheme.primary,
              inactiveTrackColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 16),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 32),
            ),
            child: Slider(
              value: _goalSpeed,
              min: 0.0,
              max: 2.0,
              divisions: 2,
              onChanged: (val) {
                setState(() => _goalSpeed = val);
                HapticFeedback.selectionClick();
              },
            ),
          ),
          const Gap(16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("🐢", style: TextStyle(fontSize: 32)),
              Text("🐇", style: TextStyle(fontSize: 32)),
              Text("🐆", style: TextStyle(fontSize: 32)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
      String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        onTap();
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const Gap(16),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroPage() {
    return _buildPageContent(
      title: "Let's learn about your nutrient level",
      subtitle: "Discover how your nutrient intake shapes your health and energy.",
      child: Center(
        child: Column(
          children: [
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.amberAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: const Center(
                  child: Icon(Icons.description_outlined,
                      size: 100, color: Colors.orange)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionKnowledgePage() {
    return _buildPageContent(
      title: "Do you have a basic understanding of nutrition?",
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildOptionCard(
                'Have in-depth knowledge',
                Icons.emoji_objects,
                _nutritionKnowledge == 'Have in-depth knowledge',
                () => setState(
                    () => _nutritionKnowledge = 'Have in-depth knowledge')),
            const Gap(16),
            _buildOptionCard(
                'Some understanding but not much',
                Icons.lightbulb_outline,
                _nutritionKnowledge == 'Some understanding but not much',
                () => setState(() =>
                    _nutritionKnowledge = 'Some understanding but not much')),
            const Gap(16),
            _buildOptionCard(
                'Interested but lack knowledge',
                Icons.help_outline,
                _nutritionKnowledge == 'Interested but lack knowledge',
                () => setState(
                    () => _nutritionKnowledge = 'Interested but lack knowledge')),
            const Gap(16),
            _buildOptionCard(
                'Not interested at all',
                Icons.cancel_outlined,
                _nutritionKnowledge == 'Not interested at all',
                () => setState(
                    () => _nutritionKnowledge = 'Not interested at all')),
          ],
        ),
      ),
    );
  }

  Widget _buildDietHistoryPage() {
    return _buildPageContent(
      title:
          "Have you ever tried weight loss methods involving a restricted diet?",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildOptionCard("Yes", Icons.check_circle, _dietHistory == true,
              () => setState(() => _dietHistory = true)),
          const Gap(16),
          _buildOptionCard("No", Icons.cancel, _dietHistory == false,
              () => setState(() => _dietHistory = false)),
        ],
      ),
    );
  }

  Widget _buildFoodLabelsPage() {
    return _buildPageContent(
      title: "Do you know how to read food labels?",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildOptionCard('Very well', Icons.visibility,
              _foodLabelKnowledge == 'Very well',
              () => setState(() => _foodLabelKnowledge = 'Very well')),
          const Gap(16),
          _buildOptionCard('Somewhat well', Icons.visibility_outlined,
              _foodLabelKnowledge == 'Somewhat well',
              () => setState(() => _foodLabelKnowledge = 'Somewhat well')),
          const Gap(16),
          _buildOptionCard('Not at all', Icons.visibility_off,
              _foodLabelKnowledge == 'Not at all',
              () => setState(() => _foodLabelKnowledge = 'Not at all')),
        ],
      ),
    );
  }

  Widget _buildTrackingHistoryPage() {
    return _buildPageContent(
      title:
          "Have you ever tried tracking your diet or calorie intake?",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildOptionCard('Frequently track', Icons.edit_note,
              _trackingHistory == 'Frequently track',
              () => setState(() => _trackingHistory = 'Frequently track')),
          const Gap(16),
          _buildOptionCard('Occasionally track', Icons.note_add,
              _trackingHistory == 'Occasionally track',
              () => setState(() => _trackingHistory = 'Occasionally track')),
          const Gap(16),
          _buildOptionCard('Never track', Icons.note_alt_outlined,
              _trackingHistory == 'Never track',
              () => setState(() => _trackingHistory = 'Never track')),
        ],
      ),
    );
  }

  String _getSpeedLabel() {
    if (_goalSpeed < 0.5) return "Slow & Steady";
    if (_goalSpeed > 1.5) return "Aggressive";
    return "Balanced";
  }
}

