import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../core/providers/meal_provider.dart';
import '../../core/services/profile_service.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  final _profileService = ProfileService();
  
  bool _isLoading = true;
  String _selectedMetric = 'Calories'; // Calories, Protein, Carbs, Fat

  final Map<String, Color> _metricColors = {
    'Calories': Colors.black,
    'Protein': Colors.blueAccent,
    'Carbs': Colors.orangeAccent,
    'Fat': Colors.redAccent,
  };

  // Default goals, updated from profile
  final Map<String, double> _metricGoals = {
    'Calories': 2000,
    'Protein': 150,
    'Carbs': 250,
    'Fat': 70,
  };

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final targets = await _profileService.calculateDailyTargets();
    
    if (mounted) {
      setState(() {
        _metricGoals['Calories'] = targets['calories']!.toDouble();
        _metricGoals['Protein'] = targets['protein']!.toDouble();
        _metricGoals['Carbs'] = targets['carbs']!.toDouble();
        _metricGoals['Fat'] = targets['fat']!.toDouble();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final weeklyStatsAsync = ref.watch(weeklyStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : weeklyStatsAsync.when(
                data: (weeklyData) => SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weekly Insights',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        'Last 7 Days Performance',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Gap(24),

                      // Health Grade Card
                      _buildHealthGradeCard(weeklyData),
                      const Gap(24),

                      // Summary Cards
                      _buildSummaryCards(weeklyData),
                      const Gap(24),

                      // Metric Selector
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _metricColors.keys.map((metric) {
                            final isSelected = _selectedMetric == metric;
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: ChoiceChip(
                                label: Text(metric),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedMetric = metric);
                                  }
                                },
                                selectedColor: _metricColors[metric],
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected ? Colors.transparent : Colors.grey[300]!,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const Gap(24),

                      // Main Chart
                      _buildMainChart(weeklyData),
                      const Gap(24),

                      // Macro Distribution
                      _buildMacroPieChart(weeklyData),
                      const Gap(40),
                    ],
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
      ),
    );
  }

  Widget _buildHealthGradeCard(List<Map<String, dynamic>> weeklyData) {
    // Calculate Grade
    int daysOnTrack = 0;
    final calorieGoal = _metricGoals['Calories']!;
    
    for (var day in weeklyData) {
      final cals = (day['calories'] as int).toDouble();
      if (cals > 0 && cals <= calorieGoal * 1.1 && cals >= calorieGoal * 0.8) {
        daysOnTrack++;
      }
    }

    String grade = 'F';
    Color gradeColor = Colors.red;
    String message = 'Needs improvement';

    if (daysOnTrack >= 6) {
      grade = 'A';
      gradeColor = Colors.green;
      message = 'Excellent work!';
    } else if (daysOnTrack >= 5) {
      grade = 'B';
      gradeColor = Colors.blue;
      message = 'Great job!';
    } else if (daysOnTrack >= 4) {
      grade = 'C';
      gradeColor = Colors.orange;
      message = 'Good effort';
    } else if (daysOnTrack >= 3) {
      grade = 'D';
      gradeColor = Colors.deepOrange;
      message = 'Getting there';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.grey[900]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: gradeColor, width: 4),
            ),
            child: Center(
              child: Text(
                grade,
                style: TextStyle(
                  color: gradeColor,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const Gap(24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Grade',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Gap(4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(4),
                Text(
                  '$daysOnTrack/7 days on track',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<Map<String, dynamic>> weeklyData) {
    // Calculate stats
    double totalCals = 0;
    int daysOnTrack = 0;
    final calorieGoal = _metricGoals['Calories']!;

    for (var day in weeklyData) {
      final cals = (day['calories'] as int).toDouble();
      totalCals += cals;
      // Allow 10% buffer
      if (cals > 0 && cals <= calorieGoal * 1.1 && cals >= calorieGoal * 0.8) {
        daysOnTrack++;
      }
    }
    final avgCals = (totalCals / 7).round();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Avg Calories',
            '$avgCals',
            Icons.local_fire_department,
            Colors.orange,
          ),
        ),
        const Gap(16),
        Expanded(
          child: _buildStatCard(
            'On Track',
            '$daysOnTrack/7 Days',
            Icons.check_circle,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const Gap(12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainChart(List<Map<String, dynamic>> weeklyData) {
    final goal = _metricGoals[_selectedMetric]!;
    final color = _metricColors[_selectedMetric]!;

    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_selectedMetric Trend',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Goal: ${goal.round()} ${_getUnit()}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Gap(32),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: goal * 1.5,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.black,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.round()} ${_getUnit()}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < weeklyData.length) {
                          final dateStr = weeklyData[value.toInt()]['date'] as String;
                          final date = DateTime.parse(dateStr);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('E').format(date)[0],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: goal,
                      color: color.withValues(alpha: 0.5),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                    ),
                  ],
                ),
                barGroups: weeklyData.asMap().entries.map((e) {
                  final index = e.key;
                  final data = e.value;
                  final value = (data[_selectedMetric.toLowerCase()] as int).toDouble();
                  
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: value,
                        gradient: LinearGradient(
                          colors: [
                            color,
                            color.withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        width: 16,
                        borderRadius: BorderRadius.circular(6),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: goal * 1.5,
                          color: Colors.grey[100],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPieChart(List<Map<String, dynamic>> weeklyData) {
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var day in weeklyData) {
      totalProtein += (day['protein'] as int);
      totalCarbs += (day['carbs'] as int);
      totalFat += (day['fat'] as int);
    }

    final total = totalProtein + totalCarbs + totalFat;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Macro Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(8),
          Text(
            'Weekly Average',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const Gap(32),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 40,
                      sections: [
                        _buildPieSection(totalProtein, 'Protein', Colors.blueAccent),
                        _buildPieSection(totalCarbs, 'Carbs', Colors.orangeAccent),
                        _buildPieSection(totalFat, 'Fat', Colors.redAccent),
                      ],
                    ),
                  ),
                ),
                const Gap(24),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('Protein', Colors.blueAccent, totalProtein / total),
                    const Gap(12),
                    _buildLegendItem('Carbs', Colors.orangeAccent, totalCarbs / total),
                    const Gap(12),
                    _buildLegendItem('Fat', Colors.redAccent, totalFat / total),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PieChartSectionData _buildPieSection(double value, String title, Color color) {
    return PieChartSectionData(
      color: color,
      value: value,
      title: '',
      radius: 50,
      titleStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color, double percentage) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const Gap(8),
        Text(
          '$title ${(percentage * 100).round()}%',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _getUnit() {
    return _selectedMetric == 'Calories' ? 'Cal' : 'g';
  }
}
