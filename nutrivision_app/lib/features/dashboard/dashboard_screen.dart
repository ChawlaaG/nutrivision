import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'dart:io';
import 'package:confetti/confetti.dart';

import '../../core/models/meal.dart';
import '../../core/services/profile_service.dart';
import '../../core/providers/meal_provider.dart';
import '../../core/providers/water_provider.dart';
import '../scanner/scanner_screen.dart';
import 'widgets/date_strip.dart';
import '../scanner/manual_entry_screen.dart';
import '../../core/services/workout_service.dart';
import '../../core/services/streak_service.dart';
import 'widgets/calorie_ring.dart';
import 'widgets/smart_coach_card.dart';
import '../scanner/food_search_screen.dart';
import '../scanner/barcode_scanner_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _profileService = ProfileService();
  final _workoutService = WorkoutService();
  final _streakService = StreakService();
  late ConfettiController _confettiController;
  bool _hasCelebrated = false;
  
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic> _userProfile = {};
  int _caloriesBurned = 0;
  int _currentStreak = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadUserProfile();
    _loadWorkoutData();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    await _streakService.updateStreak(); // Update first
    final streak = await _streakService.getStreak();
    if (mounted) setState(() => _currentStreak = streak);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkoutData() async {
    if (!DateUtils.isSameDay(_selectedDate, DateTime.now())) {
      setState(() => _caloriesBurned = 0);
      return;
    }
    final burned = await _workoutService.getCaloriesBurnedToday();
    if (mounted) {
      setState(() {
        _caloriesBurned = burned;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    final profile = await _profileService.getUserProfile();
    final targets = await _profileService.calculateDailyTargets();
    
    if (mounted) {
      setState(() {
        _userProfile = profile;
        _userProfile['calorie_goal'] = targets['calories'].toString();
      });
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _hasCelebrated = false; // Reset celebration for new date view
      _loadWorkoutData(); // Reload workout for selected date
    });
  }

  @override
  Widget build(BuildContext context) {
    final mealsAsync = ref.watch(dailyMealsProvider(_selectedDate));
    final int calorieGoal = int.tryParse(_userProfile['calorie_goal'] ?? '2000') ?? 2000;

    // Celebration Logic
    mealsAsync.whenData((meals) {
      int cals = meals.fold(0, (sum, m) => sum + m.calories);
      int effectiveGoal = calorieGoal + _caloriesBurned;
      if (cals >= effectiveGoal && !_hasCelebrated && DateUtils.isSameDay(_selectedDate, DateTime.now())) {
        // Delay slightly to let UI render first
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
             _confettiController.play();
             // HapticFeedback.heavyImpact(); // Optional integration
             _hasCelebrated = true; 
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickLogSheet(context),
        backgroundColor: const Color(0xFFFF7F50), // Coral/Orange color from screenshot
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // ignore: unused_result
            await ref.refresh(dailyMealsProvider(_selectedDate).future);
            // ignore: unused_result
            await ref.refresh(dailyWaterProvider(_selectedDate).future);
            await _loadUserProfile();
            await _loadWorkoutData();
          },
          child: CustomScrollView(
            slivers: [
              // Header & Date
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      DateStrip(
                        selectedDate: _selectedDate,
                        onDateSelected: _onDateSelected,
                      ),
                      const Gap(24),
                      mealsAsync.when(
                        data: (meals) => _buildEatoHeader(meals, calorieGoal),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, s) => Text('Error: $e'),
                      ),
                    ],
                  ),
                ),
              ),

              // Meal Slots
              mealsAsync.when(
                data: (meals) {
                  return SliverList(
                    delegate: SliverChildListDelegate([
                      _buildMealSection("Breakfast", meals, "Breakfast"),
                      _buildMealSection("Lunch", meals, "Lunch"),
                      _buildMealSection("Dinner", meals, "Dinner"),
                      _buildMealSection("Snack", meals, "Snack"),
                      const Gap(80),
                    ]),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: SizedBox()),
                error: (e, s) => const SliverToBoxAdapter(child: SizedBox()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickLogSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 350,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              "Quick log",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Gap(32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickLogOption(Icons.search, "Search", Colors.amber[100]!, () {
                   Navigator.pop(context);
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const FoodSearchScreen()));
                }),
                _buildQuickLogOption(Icons.camera_alt, "AI Identify", Colors.green[100]!, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ScannerScreen()));
                }),
                _buildQuickLogOption(Icons.qr_code_scanner, "Barcode", Colors.pink[100]!, () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()));
                }),
                _buildQuickLogOption(Icons.fitness_center, "Workout", Colors.orange[100]!, () {
                  Navigator.pop(context);
                  _showWorkoutDialog(context);
                }),
              ],
            ),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              style: IconButton.styleFrom(backgroundColor: Colors.grey[100]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showWorkoutDialog(BuildContext context) async {
    final durationController = TextEditingController();
    final caloriesController = TextEditingController();
    
    await showDialog(
      context: context, 
      builder: (context) {
        return AlertDialog(
          title: const Text("Log Workout"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: durationController,
                decoration: const InputDecoration(labelText: "Duration (minutes)", hintText: "30"),
                keyboardType: TextInputType.number,
              ),
              const Gap(16),
              TextField(
                controller: caloriesController,
                decoration: const InputDecoration(labelText: "Calories Burned", hintText: "300"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("Cancel")
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                final cals = int.tryParse(caloriesController.text);
                if (cals != null && cals > 0) {
                   await _workoutService.logWorkout(cals);
                   await _loadWorkoutData(); // Refresh data
                   
                   navigator.pop();
                   messenger.showSnackBar(
                     SnackBar(content: Text("Workout logged: $cals kcal"))
                   );
                }
              }, 
              child: const Text("Log")
            )
          ],
        );
      }
    );
  }

  Widget _buildQuickLogOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: Colors.black87),
          ),
          const Gap(8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEatoHeader(List<Meal> meals, int goal) {
    int consumed = meals.fold(0, (sum, m) => sum + m.calories);
    // Effective goal = Base Goal + Burned
    int effectiveGoal = goal + _caloriesBurned;

    // Macros
    int fat = meals.fold(0, (sum, m) => sum + m.fat);
    int carbs = meals.fold(0, (sum, m) => sum + m.carbs);
    int protein = meals.fold(0, (sum, m) => sum + m.protein);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
               BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 5)),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildTopStat("Food Intake", "$consumed", false),
                  
                  // Embedded Calorie Ring
                  Column(
                    children: [
                       if (_currentStreak > 0)
                         Container(
                           margin: const EdgeInsets.only(bottom: 8),
                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                           decoration: BoxDecoration(
                             color: _getStreakColor(_currentStreak).withValues(alpha: 0.1),
                             borderRadius: BorderRadius.circular(12),
                             border: Border.all(color: _getStreakColor(_currentStreak).withValues(alpha: 0.3)),
                           ),
                           child: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               Icon(Icons.local_fire_department, size: 16, color: _getStreakColor(_currentStreak)),
                               const Gap(4),
                               Text(
                                 "$_currentStreak Day Streak!", 
                                 style: TextStyle(
                                   color: _getStreakColor(_currentStreak), 
                                   fontWeight: FontWeight.bold, 
                                   fontSize: 12
                                 )
                               ),
                             ],
                           ),
                         ),
                       SizedBox(
                        height: 160, 
                        width: 160,
                        child: CalorieRing(
                          consumed: consumed,
                          goal: effectiveGoal,
                          macros: const {}, // Not showing macros inside the ring
                          meals: meals,
                          size: 160,
                          showBackground: false,
                          showMacros: false,
                        ),
                      ),
                    ],
                  ),

                  _buildTopStat("Exercise Burn", "$_caloriesBurned", false),
                ],
              ),
              const Gap(24),
              const Divider(height: 1),
              const Gap(24),
              _buildMacronutrientGrid(fat, carbs, protein),
            ],
          ),
        ),
        const Gap(16),
        SmartCoachCard(
          macros: {
            'protein': protein,
            'carbs': carbs,
            'fat': fat,
          },
          consumedCalories: consumed,
          calorieGoal: effectiveGoal,
        ),
      ],
    );
  }

  Widget _buildMealSection(String title, List<Meal> allMeals, String type) {
    List<Meal> sectionMeals = allMeals.where((m) => m.mealType == type).toList();
    int sectionCalories = sectionMeals.fold(0, (sum, m) => sum + m.calories);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // clean header
          Row(
            children: [
               Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
               const Gap(8),
               if (sectionCalories > 0)
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                   decoration: BoxDecoration(
                     color: Colors.grey[100],
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child: Text("$sectionCalories kcal", style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600)),
                 ),
               const Spacer(),
               // Add Button
               InkWell(
                 onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const ScannerScreen()));
                 },
                 borderRadius: BorderRadius.circular(20),
                 child: Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(
                      color: const Color(0xFFFF7F50).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                   ),
                   child: const Icon(Icons.add, color: Color(0xFFFF7F50), size: 20),
                 ),
               ),
            ],
          ),
          const Gap(12),
          // Meals List
          if (sectionMeals.isNotEmpty) ...[
             ...sectionMeals.map((m) => _buildMealRow(m)),
          ] else 
            // Minimal Empty State
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
              ),
              child: Center(
                child: TextButton.icon(
                  onPressed: () {
                     Navigator.push(context, MaterialPageRoute(builder: (context) => const ScannerScreen()));
                  },
                  icon: Icon(Icons.add_circle_outline, size: 18, color: Colors.grey[400]),
                  label: Text("Add $title", style: TextStyle(color: Colors.grey[400])),
                  style: TextButton.styleFrom(splashFactory: NoSplash.splashFactory),
                )
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildMealRow(Meal meal) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ManualEntryScreen(
              imagePath: meal.imagePath,
              meal: meal,
            ),
          ),
        );
        // ignore: unused_result
        ref.refresh(dailyMealsProvider(_selectedDate));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(16),
           border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            // Meal Image
            Container(
              height: 50, width: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
                image: meal.imagePath.isNotEmpty 
                  ? DecorationImage(
                      image: FileImage(File(meal.imagePath)),
                      fit: BoxFit.cover,
                    )
                  : null
              ),
              child: meal.imagePath.isEmpty 
                 ? Icon(Icons.restaurant, color: Colors.grey[300], size: 20)
                 : null,
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meal.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Gap(4),
                  Row(
                    children: [
                       _buildMacroBadge("${meal.protein}g P", Colors.blue),
                       const Gap(6),
                       _buildMacroBadge("${meal.carbs}g C", Colors.orange),
                       const Gap(6),
                       _buildMacroBadge("${meal.fat}g F", Colors.red),
                    ],
                  )
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("${meal.calories}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("kcal", style: TextStyle(color: Colors.grey[700], fontSize: 10)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMacroBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTopStat(String label, String value, bool isMain) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w600)),
        const Gap(4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ],
    );
  }

  Widget _buildMacronutrientGrid(int fat, int carbs, int protein) {
    // 2 columns, 3 rows equivalent
    return Column(
      children: [
        Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween, 
           children: [
             _buildMacroItem("Fat", "${fat}g", "0/48g"),
             _buildMacroItem("Net Carbs", "${carbs}g", "0/269g"),
           ]
        ),
        const Gap(16),
        Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween, 
           children: [
             _buildMacroItem("Protein", "${protein}g", "0/161g"),
             _buildMacroItem("Fiber", "0g", "0/34g"), // Placeholder
           ]
        ),
        const Gap(16),
        Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween, 
           children: [
             _buildMacroItem("Sodium", "0mg", "0/2.3k mg"), // Placeholder
             _buildMacroItem("Sugar", "0g", "0/35g"), // Placeholder
           ]
        ),
      ],
    );
  }

  Widget _buildMacroItem(String label, String value, String goal) {
    return SizedBox(
      width: 140, // Fixed width for alignment
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(goal, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Color _getStreakColor(int streak) {
    if (streak >= 7) return Colors.purple; // Epic streak
    if (streak >= 3) return Colors.orange; // Heating up
    return Colors.amber; // Started
  }
}
