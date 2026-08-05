import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _favoritesKey = 'favorite_ids';
  static const _columnsKey = 'grid_columns';
  static const _speechRateKey = 'speech_rate';

  Future<Set<String>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_favoritesKey) ?? const <String>[]).toSet();
  }

  Future<void> saveFavorites(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, ids.toList());
  }

  Future<int> loadColumns() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_columnsKey) ?? 2;
  }

  Future<void> saveColumns(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_columnsKey, value);
  }

  Future<double> loadSpeechRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_speechRateKey) ?? 0.36;
  }

  Future<void> saveSpeechRate(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_speechRateKey, value);
  }
}
