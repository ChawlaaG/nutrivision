import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../core/repositories/food_repository.dart';
import 'add_custom_food_screen.dart';
import '../scanner/barcode_scanner_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _repository = FoodRepository();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() => _results = []);
      return;
    }
    _performSearch(_searchController.text);
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    try {
      final results = await _repository.searchFoods(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onFoodSelected(Map<String, dynamic> food) {
    // Return selected food to previous screen (e.g., Dashboard or Meal Log)
    Navigator.pop(context, food);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('Search Food'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for food (e.g., Apple, Rice)',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty && _searchController.text.isNotEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _results.length,
                        separatorBuilder: (context, index) => const Gap(12),
                        itemBuilder: (context, index) {
                          final food = _results[index];
                          return _buildFoodItem(food);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'scan',
            onPressed: _scanBarcode,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            child: const Icon(Icons.qr_code_scanner),
          ),
          const Gap(16),
          FloatingActionButton.extended(
            heroTag: 'create',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddCustomFoodScreen()),
              );
              if (result == true) {
                // Refresh search if needed or show success
                _performSearch(_searchController.text);
              }
            },
            label: const Text('Create Food'),
            icon: const Icon(Icons.add),
            backgroundColor: Colors.black,
          ),
        ],
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (barcode != null && barcode is String) {
      setState(() => _isLoading = true);
      try {
        final product = await _repository.getProductByBarcode(barcode);
        if (mounted) {
          setState(() => _isLoading = false);
          if (product != null) {
            _onFoodSelected(product);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Product not found')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const Gap(16),
          Text(
            'No foods found for "${_searchController.text}"',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const Gap(24),
          ElevatedButton(
            onPressed: () async {
               final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddCustomFoodScreen()),
              );
              if (result == true) {
                _performSearch(_searchController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Create Custom Food'),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItem(Map<String, dynamic> food) {
    final isCustom = food['source'] == 'custom';
    return InkWell(
      onTap: () => _onFoodSelected(food),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCustom ? Colors.orange[50] : Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCustom ? Icons.edit_note : Icons.restaurant,
                color: isCustom ? Colors.orange : Colors.green,
              ),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    '${food['calories']} kcal • ${food['protein']}p • ${food['carbs']}c • ${food['fat']}f',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.add_circle_outline, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}
