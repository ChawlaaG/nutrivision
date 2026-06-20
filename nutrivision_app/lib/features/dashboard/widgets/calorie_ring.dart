import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../../core/models/meal.dart';

class CalorieRing extends StatefulWidget {
  final int consumed;
  final int goal;
  final Map<String, int> macros;
  final List<Meal> meals;
  final double size;
  final bool showBackground;
  final bool showMacros;

  const CalorieRing({
    super.key,
    required this.consumed,
    required this.goal,
    required this.macros,
    required this.meals,
    this.size = 300,
    this.showBackground = true,
    this.showMacros = true,
  });

  @override
  State<CalorieRing> createState() => _CalorieRingState();
}

class _CalorieRingState extends State<CalorieRing> {
  Meal? _selectedMeal;
  Timer? _resetTimer;

  void _onMealTapped(Meal meal) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedMeal = meal;
    });
    
    // Reset timer
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _selectedMeal = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.showBackground ? const EdgeInsets.all(24) : EdgeInsets.zero,
      decoration: widget.showBackground ? BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // 1. The Circular Track (Background + Eating Window + Calorie Glow)
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: ClockTrackPainter(
                    consumed: widget.consumed,
                    goal: widget.goal,
                    meals: widget.meals,
                  ),
                ),
              ),
              
              // 2. Center Content (Dynamic: Default vs Selected Meal)
              // Scale down text slightly if size is small
              SizedBox(
                width: widget.size * 0.6,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _selectedMeal != null
                      ? _buildSelectedMealInfo(_selectedMeal!)
                      : _buildDefaultCenterInfo(),
                ),
              ),

              // 3. Meal Icons positioned on the ring
              for (var meal in widget.meals)
                _PositionedMealIcon(
                  meal: meal,
                  radius: (widget.size / 2) - 15,
                  iconSize: widget.size < 200 ? 32 : 44, // Smaller icons for smaller ring
                  onTap: () => _onMealTapped(meal),
                ),
            ],
          ),
          if (widget.showMacros) ...[
            const Gap(24),
            // 4. Macro Summary below
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMacroItem('Protein', '${widget.macros['protein']}g', Colors.blue),
                _buildMacroItem('Carbs', '${widget.macros['carbs']}g', Colors.orange),
                _buildMacroItem('Fat', '${widget.macros['fat']}g', Colors.red),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultCenterInfo() {
    final bool isSmall = widget.size < 200;
    
    return Column(
      key: const ValueKey('default'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Calories Left',
          style: TextStyle(
            fontSize: isSmall ? 10 : 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Gap(4),
        Text(
          '${widget.goal - widget.consumed}',
          style: TextStyle(
            fontSize: isSmall ? 28 : 48,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C3E50),
            height: 1.0,
          ),
        ),
        const Gap(4),
        Text(
          'of ${widget.goal} kcal',
          style: TextStyle(
            fontSize: isSmall ? 10 : 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedMealInfo(Meal meal) {
    final bool isSmall = widget.size < 200;

    return Column(
      key: ValueKey('meal_${meal.id}'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            meal.mealType.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const Gap(8),
        Text(
          meal.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isSmall ? 14 : 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C3E50),
          ),
        ),
        const Gap(4),
        Text(
          '${meal.calories} kcal',
          style: TextStyle(
            fontSize: isSmall ? 18 : 24,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFD0FD3E), // Neon Lime for highlight
            shadows: const [Shadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
        ),
      ],
    );
  }

  Widget _buildMacroItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _PositionedMealIcon extends StatelessWidget {
  final Meal meal;
  final double radius;
  final double iconSize;
  final VoidCallback onTap;

  const _PositionedMealIcon({
    required this.meal,
    required this.radius,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hour = meal.timestamp.hour;
    final minute = meal.timestamp.minute;
    final double dayFraction = (hour * 60 + minute) / (24 * 60);
    final double angle = (dayFraction * 2 * math.pi) - (math.pi / 2);

    final double x = radius * math.cos(angle);
    final double y = radius * math.sin(angle);

    return Transform.translate(
      offset: Offset(x, y),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: iconSize, 
          height: iconSize,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(iconSize * 0.07), // Scaling padding
          child: ClipOval(
            child: meal.imagePath.isNotEmpty
                ? Image.file(
                    File(meal.imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (c, o, s) => Icon(Icons.fastfood, size: iconSize * 0.5, color: Colors.orange),
                  )
                : Icon(Icons.fastfood, size: iconSize * 0.5, color: Colors.orange),
          ),
        ),
      ),
    );
  }
}

class ClockTrackPainter extends CustomPainter {
  final int consumed;
  final int goal;
  final List<Meal> meals;

  ClockTrackPainter({
    required this.consumed,
    required this.goal,
    required this.meals,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 15;

    // 1. Background Track
    final trackPaint = Paint()
      ..color = Colors.grey[100]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Eating Window (Arc from first meal to last meal)
    if (meals.isNotEmpty && meals.length > 1) {
      // Find min and max timestamp
      // Assuming meals list might be unsorted, map to minutes
      final minutesOfDay = meals.map((m) => m.timestamp.hour * 60 + m.timestamp.minute).toList();
      minutesOfDay.sort();
      
      final startMin = minutesOfDay.first;
      final endMin = minutesOfDay.last;
      
      // Convert to angles
      // 00:00 = -pi/2
      final startAngle = ((startMin / (24 * 60)) * 2 * math.pi) - (math.pi / 2);
      final endAngle = ((endMin / (24 * 60)) * 2 * math.pi) - (math.pi / 2);
      
      var sweep = endAngle - startAngle;
      if (sweep < 0) sweep += 2 * math.pi; // Handle midnight crossing if any (though logic above assumes same day)

      final windowPaint = Paint()
        ..color = Colors.orange.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        windowPaint,
      );
    }

    // 3. Current Time "Now" Dot
    final now = DateTime.now();
    final double dayFraction = (now.hour * 60 + now.minute) / (24 * 60);
    final double nowAngle = (dayFraction * 2 * math.pi) - (math.pi / 2);
    
    final knobPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
      
    final knobX = center.dx + radius * math.cos(nowAngle);
    final knobY = center.dy + radius * math.sin(nowAngle);
    
    // Draw small track marker for Now
    canvas.drawCircle(Offset(knobX, knobY), 6, knobPaint);


    // 4. Calorie Progress Glow (Inner Ring)
    // Draw this slightly inside the main track
    final progressRadius = radius - 24; 
    final progressPct = (consumed / goal).clamp(0.0, 1.0);
    final progressSweep = progressPct * 2 * math.pi;

    final glowPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFD0FD3E), Color(0xFF2E7D32)], // Neon Lime to Green
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: progressRadius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4); // Glow effect

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: progressRadius),
      -math.pi / 2, // Start at top
      progressSweep,
      false,
      glowPaint,
    );
     // Draw backing for progress glow for contrast? No, keep it minimal.
  }

  @override
  bool shouldRepaint(covariant ClockTrackPainter oldDelegate) {
    return oldDelegate.consumed != consumed || 
           oldDelegate.goal != goal ||
           oldDelegate.meals != meals;
  }
}

