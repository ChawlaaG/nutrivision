import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'dart:math' as math;
import 'package:flutter/services.dart'; // For Haptics

import 'package:nutrivision_app/core/services/fasting_service.dart';
import 'package:nutrivision_app/core/services/health_service.dart';
import 'package:nutrivision_app/core/providers/water_provider.dart';
import 'package:nutrivision_app/core/providers/streak_provider.dart';

// --- Base Tile Widget ---
class BentoTile extends StatelessWidget {
  final Widget child;
  final Color color;
  final VoidCallback? onTap;

  const BentoTile({
    super.key,
    required this.child,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// --- Steps Tile ---
class StepsTile extends StatefulWidget {
  const StepsTile({super.key});

  @override
  State<StepsTile> createState() => _StepsTileState();
}

class _StepsTileState extends State<StepsTile> {
  int _steps = 0;
  final HealthService _healthService = HealthService();

  @override
  void initState() {
    super.initState();
    _fetchSteps();
  }

  Future<void> _fetchSteps() async {
    final steps = await _healthService.getTodaySteps();
    if (mounted) setState(() => _steps = steps);
  }

  @override
  Widget build(BuildContext context) {
    return BentoTile(
      color: Colors.white,
      onTap: _fetchSteps,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.directions_walk, color: Colors.orange, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_steps',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Steps',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Water Tile (Animated) ---
class WaterTile extends ConsumerStatefulWidget {
  final DateTime date;
  const WaterTile({super.key, required this.date});

  @override
  ConsumerState<WaterTile> createState() => _WaterTileState();
}

class _WaterTileState extends ConsumerState<WaterTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waterAsync = ref.watch(dailyWaterProvider(widget.date));
    
    // Default 2500ml target for visualization
    const int targetMl = 2500;
    
    return waterAsync.when(
      data: (ml) {
        final double fillPct = (ml / targetMl).clamp(0.0, 1.0);
        
        return GestureDetector(
          onTap: () async {
            // Haptics
            await HapticFeedback.mediumImpact();
            // Add 250ml
            await ref.read(waterControllerProvider.notifier).addWater(250, widget.date);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // 1. Wave Background
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: WavePainter(
                          animationValue: _controller.value,
                          fillPercent: fillPct,
                          color: const Color(0xFFE3F2FD),
                          waterColor: const Color(0xFF90CAF9).withValues(alpha: 0.5),
                        ),
                      );
                    },
                  ),
                ),
                
                // 2. Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.water_drop, color: Colors.blue, size: 28),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (ml / 250).toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              shadows: [Shadow(color: Colors.white, blurRadius: 2)],
                            ),
                          ),
                          const Text(
                            'Glasses',
                            style: TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. Add Button
                Positioned(
                  right: 16,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 16, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;
  final double fillPercent;
  final Color color;
  final Color waterColor;

  WavePainter({
    required this.animationValue,
    required this.fillPercent,
    required this.color,
    required this.waterColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(Offset.zero & size, Paint()..color = color);

    if (fillPercent == 0) return;

    final paint = Paint()..color = waterColor;
    final path = Path();

    // Invert Y because canvas coords top-left is 0,0
    // fillPercent 0.0 -> y = height. fillPercent 1.0 -> y = 0.
    // However, we want to start from bottom.
    // Base height level
    final baseHeight = size.height * (1 - fillPercent);

    path.moveTo(0, baseHeight);

    // Draw sine wave
    for (double i = 0.0; i <= size.width; i++) {
        // Simple Sine: y = A sin(kx - wt)
        // A = 10 (amplitude)
        // k = 2pi / width * 1.5 (1.5 waves)
        // w = 2pi * animation
      path.lineTo(
        i,
        baseHeight + 
        10 * math.sin((i / size.width * 2 * math.pi * 1.5) + (animationValue * 2 * math.pi)),
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) => true;
}

// --- Fasting Tile (Visual) ---
class FastingTile extends StatefulWidget {
  const FastingTile({super.key});

  @override
  State<FastingTile> createState() => _FastingTileState();
}

class _FastingTileState extends State<FastingTile> with SingleTickerProviderStateMixin {
  final FastingService _service = FastingService();
  late AnimationController _pulseController;
  bool _isFasting = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
       vsync: this, 
       duration: const Duration(seconds: 2)
    )..repeat(reverse: true);
    
    _checkFasting();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_isFasting) _checkFasting();
    });
  }

  Future<void> _checkFasting() async {
    final isFasting = await _service.isFasting();
    final start = await _service.getStartTime();
    if (mounted) {
      setState(() {
        _isFasting = isFasting;
        if (isFasting && start != null) {
          _elapsed = DateTime.now().difference(start);
        } else {
          _elapsed = Duration.zero;
        }
      });
    }
  }

  Color _getPhaseColor(Duration elapsed) {
    if (elapsed.inHours < 4) return Colors.green; // Digesting
    if (elapsed.inHours < 12) return Colors.orange; // Burning
    return Colors.redAccent; // Ketosis
  }

  String _getPhaseText(Duration elapsed) {
    if (elapsed.inHours < 4) return "Digesting";
    if (elapsed.inHours < 12) return "Fat Burn";
    return "Ketosis";
  }

  @override
  Widget build(BuildContext context) {
    final color = _isFasting ? _getPhaseColor(_elapsed) : Colors.grey;
    final phase = _isFasting ? _getPhaseText(_elapsed) : "Ready";
    
    // Assume 16 hour target for visual circle
    final double percent = (_elapsed.inMinutes / (16 * 60)).clamp(0.0, 1.0);

    return BentoTile(
      color: Colors.white, 
      onTap: () async {
        if (_isFasting) {
          final shouldEnd = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('End Fast?'),
              content: const Text('Great job! Ready to break your fast?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                TextButton(
                  onPressed: () => Navigator.pop(context, true), 
                  child: const Text('End Fast', style: TextStyle(color: Colors.red))
                ),
              ],
            ),
          );

          if (shouldEnd == true) {
            await _service.endFast();
            _checkFasting();
          }
        } else {
          await _service.startFast();
          _checkFasting();
        }
      },
      child: Stack(
        children: [
          // Background Glow if Fasting
          if (_isFasting)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.1 + (_pulseController.value * 0.1)),
                          blurRadius: 20 + (_pulseController.value * 10),
                          spreadRadius: 5,
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
            
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header Icon and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Icon(Icons.bolt, color: color, size: 28),
                   if (_isFasting)
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                       decoration: BoxDecoration(
                         color: color.withValues(alpha: 0.1),
                         borderRadius: BorderRadius.circular(10),
                       ),
                       child: Text(phase, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
                     )
                ],
              ),
              
              // Timer Display
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isFasting 
                       ? '${_elapsed.inHours}:${(_elapsed.inMinutes % 60).toString().padLeft(2, '0')}' 
                       : 'Start',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _isFasting ? Colors.black : Colors.grey[400],
                    ),
                  ),
                  Text(
                    _isFasting ? 'Elapsed' : 'Tap to Fast',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Progress Ring (Subtle)
          if (_isFasting)
          Positioned(
             right: 0,
             bottom: 0,
             child: SizedBox(
               height: 30, 
               width: 30,
               child: CircularProgressIndicator(
                 value: percent,
                 backgroundColor: Colors.grey[100],
                 color: color,
                 strokeWidth: 4,
               ),
             ),
          )
        ],
      ),
    );
  }
}

// --- Streak Tile ---
class StreakTile extends ConsumerWidget {
  const StreakTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);

    return BentoTile(
      color: const Color(0xFFFFF3E0), // Light Orange
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              streakAsync.when(
                data: (streak) => Text(
                  '$streak',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                loading: () => const Text('...', style: TextStyle(fontSize: 24)),
                error: (_, __) => const Text('0', style: TextStyle(fontSize: 24)),
              ),
              const Text(
                'Day Streak',
                style: TextStyle(color: Colors.brown, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
