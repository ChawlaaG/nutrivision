class ScannedFoodItem {
  String name;
  int caloriesPerUnit;
  int proteinPerUnit;
  int carbsPerUnit;
  int fatPerUnit;
  double quantity;

  ScannedFoodItem({
    required this.name,
    required this.caloriesPerUnit,
    required this.proteinPerUnit,
    required this.carbsPerUnit,
    required this.fatPerUnit,
    this.quantity = 1.0,
  });

  int get totalCalories => (caloriesPerUnit * quantity).round();
  int get totalProtein => (proteinPerUnit * quantity).round();
  int get totalCarbs => (carbsPerUnit * quantity).round();
  int get totalFat => (fatPerUnit * quantity).round();
}
