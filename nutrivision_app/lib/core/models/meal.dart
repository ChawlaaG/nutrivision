class Meal {
  final int? id;
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String imagePath;
  final DateTime timestamp;
  final String mealType; // 'breakfast', 'lunch', 'dinner', 'snack'

  Meal({
    this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.imagePath,
    required this.timestamp,
    this.mealType = 'snack',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'image_path': imagePath,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'meal_type': mealType,
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'],
      name: map['name'],
      calories: map['calories'],
      protein: map['protein'],
      carbs: map['carbs'],
      fat: map['fat'],
      imagePath: map['image_path'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      mealType: map['meal_type'] ?? 'snack',
    );
  }
}
