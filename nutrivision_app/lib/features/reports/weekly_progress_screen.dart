import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../core/services/database_helper.dart';

class WeeklyProgressScreen extends StatefulWidget {
  const WeeklyProgressScreen({super.key});

  @override
  State<WeeklyProgressScreen> createState() => _WeeklyProgressScreenState();
}

class _WeeklyProgressScreenState extends State<WeeklyProgressScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _weeklyData = [];
  int _averageCalories = 0;

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }

  Future<void> _loadWeeklyData() async {
    final now = DateTime.now();
    List<Map<String, dynamic>> data = [];
    int totalCals = 0;

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final dayName = DateFormat('E').format(date); // Mon, Tue...
      
      final macros = await DatabaseHelper.instance.getDailyMacros(dateStr);
      final calories = macros['calories']!;
      
      totalCals += calories;
      data.add({
        'day': dayName,
        'calories': calories,
        'isToday': i == 0,
        'date': dateStr,
      });
    }

    if (mounted) {
      setState(() {
        _weeklyData = data;
        _averageCalories = (totalCals / 7).round();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Weekly Success'),
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(),
                  const Gap(24),
                  const Text("Calorie Trend", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Gap(16),
                  _buildBarChart(),
                  const Gap(24),
                  _buildInsightCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0A1E35), Color(0xFF1B3B5F)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Average Daily", style: TextStyle(color: Colors.blue[100], fontSize: 12)),
              const Gap(4),
              Text("$_averageCalories kcal", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.insights, color: Colors.white, size: 30),
          )
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    int maxVal = 2500; // Default max
    for (var d in _weeklyData) {
      if (d['calories'] > maxVal) maxVal = d['calories'];
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _weeklyData.map((d) {
          final heightFactor = (d['calories'] as int) / maxVal;
          final isToday = d['isToday'] as bool;
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
               Text("${d['calories']}", style: TextStyle(fontSize: 10, color: Colors.grey[600])),
               const Gap(8),
               Container(
                 width: 30, // Fixed bar width
                 height: 120 * heightFactor, // Scale to chart height
                 decoration: BoxDecoration(
                   color: isToday ? Colors.orange : Colors.blue[100],
                   borderRadius: BorderRadius.circular(8),
                 ),
               ),
               const Gap(8),
               Text(d['day'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInsightCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: const Row(
        children: [
          Icon(Icons.tips_and_updates, color: Colors.green),
          Gap(16),
          Expanded(
            child: Text(
              "Great consistency! Try to hit your protein goal more often next week to maximize muscle recovery.",
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
            ),
          )
        ],
      ),
    );
  }
}
