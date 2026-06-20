import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';


class ProcessingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const ProcessingScreen({super.key, required this.onComplete});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  int _progress = 0;
  int _currentStep = 0;
  Timer? _timer;

  final List<String> _steps = [
    'Analyzing body composition...',
    'Calculating metabolic rate...',
    'Optimizing macro split...',
    'Finalizing your plan...',
  ];

  @override
  void initState() {
    super.initState();
    _startProcessing();
  }

  void _startProcessing() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_progress >= 100) {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 500), widget.onComplete);
      } else {
        setState(() {
          _progress++;
          // Update step based on progress
          if (_progress < 30) {
            _currentStep = 0;
          } else if (_progress < 60) {
            _currentStep = 1;
          } else if (_progress < 90) {
            _currentStep = 2;
          } else {
            _currentStep = 3;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Big Percentage
              Text(
                '$_progress%',
                style: const TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: -2,
                ),
              ),
              const Gap(40),

              // Gradient Progress Bar
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.grey[200],
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progress / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: const LinearGradient(
                        colors: [Colors.black, Colors.grey],
                      ),
                    ),
                  ),
                ),
              ),
              const Gap(60),

              // Checklist Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: List.generate(_steps.length, (index) {
                    final isCompleted = index < _currentStep;
                    final isCurrent = index == _currentStep;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted
                                  ? Colors.green
                                  : (isCurrent
                                      ? Colors.black
                                      : Colors.grey[200]),
                            ),
                            child: isCompleted
                                ? const Icon(Icons.check,
                                    size: 16, color: Colors.white)
                                : (isCurrent
                                    ? const Padding(
                                        padding: EdgeInsets.all(6),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null),
                          ),
                          const Gap(16),
                          Text(
                            _steps[index],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  isCurrent ? FontWeight.bold : FontWeight.w500,
                              color: isCurrent ? Colors.black : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
