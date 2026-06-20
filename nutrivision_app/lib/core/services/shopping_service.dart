import 'package:shared_preferences/shared_preferences.dart';

class ShoppingService {
  static const String _keyShoppingList = 'shopping_list';

  Future<List<String>> getItems() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyShoppingList) ?? [];
  }

  Future<void> addItem(String item) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyShoppingList) ?? [];
    if (!list.contains(item)) {
      list.add(item);
      await prefs.setStringList(_keyShoppingList, list);
    }
  }

  Future<void> removeItem(String item) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyShoppingList) ?? [];
    list.remove(item);
    await prefs.setStringList(_keyShoppingList, list);
  }
}
