import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nutrivision_app/core/services/fasting_service.dart';

class FastingCard extends StatefulWidget {
  const FastingCard({super.key});

  @override
  State<FastingCard> createState() => _FastingCardState();
}

class _FastingCardState extends State<FastingCard> {
  final FastingService _fastingService = FastingService();
  bool _isFasting = false;
  DateTime? _startTime;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadState() async {
    final isFasting = await _fastingService.isFasting();
    final startTime = await _fastingService.getStartTime();
    
    if (mounted) {
      setState(() {
        _isFasting = isFasting;
        _startTime = startTime;
      });
      if (_isFasting) {
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startTime != null) {
        setState(() {
          _elapsed = DateTime.now().difference(_startTime!);
        });
      }
    });
  }

  Future<void> _toggleFasting() async {
    if (_isFasting) {
      await _fastingService.endFast();
      _timer?.cancel();
      setState(() {
        _isFasting = false;
        _elapsed = Duration.zero;
      });
    } else {
      await _fastingService.startFast();
      await _loadState();
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.timer, color: Colors.purple),
                  Gap(8),
                  Text(
                    'Fasting Timer',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isFasting ? Colors.green.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isFasting ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: _isFasting ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),
          if (_isFasting)
            Text(
              _formatDuration(_elapsed),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            )
          else
            const Text(
              'Ready to start?',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          const Gap(16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _toggleFasting,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFasting ? Colors.red.shade50 : Colors.black,
                foregroundColor: _isFasting ? Colors.red : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(_isFasting ? 'End Fast' : 'Start Fasting'),
            ),
          ),
        ],
      ),
    );
  }
}
