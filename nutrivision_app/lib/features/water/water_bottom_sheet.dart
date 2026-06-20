import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../core/providers/water_provider.dart';

class WaterBottomSheet extends ConsumerWidget {
  const WaterBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Water',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Gap(24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWaterOption(context, ref, 250, 'Small Glass'),
              _buildWaterOption(context, ref, 500, 'Large Glass'),
              _buildWaterOption(context, ref, 750, 'Bottle'),
            ],
          ),
          const Gap(32),
        ],
      ),
    );
  }

  Widget _buildWaterOption(BuildContext context, WidgetRef ref, int amount, String label) {
    return InkWell(
      onTap: () {
        ref.read(waterControllerProvider.notifier).addWater(amount, DateTime.now());
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_drink, color: Colors.blue, size: 32),
          ),
          const Gap(8),
          Text(
            '$amount ml',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
