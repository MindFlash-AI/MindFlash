import 'package:shared_preferences/shared_preferences.dart';

class EnergyService {
  static const int maxEnergy = 15;
  static const String _energyKey = 'ai_energy_count';
  static const String _dateKey = 'ai_last_reset_date';

  int _currentEnergy = maxEnergy;
  late SharedPreferences _prefs;

  int get currentEnergy => _currentEnergy;

  // Initializes the service and checks if it's a new day
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _checkDailyReset();
  }

  void _checkDailyReset() {
    // Get today's date as a string (e.g., "2023-10-27")
    String today = DateTime.now().toIso8601String().split('T')[0];
    String? lastReset = _prefs.getString(_dateKey);

    if (lastReset != today) {
      // It's a new day! Reset energy to max
      _currentEnergy = maxEnergy;
      _prefs.setInt(_energyKey, _currentEnergy);
      _prefs.setString(_dateKey, today);
    } else {
      // Same day, load the saved energy count (default to max if null)
      _currentEnergy = _prefs.getInt(_energyKey) ?? maxEnergy;
    }
  }

  // Deduct 1 energy. Returns true if successful, false if out of energy.
  Future<bool> deductEnergy() async {
    if (_currentEnergy > 0) {
      _currentEnergy--;
      await _prefs.setInt(_energyKey, _currentEnergy);
      return true;
    }
    return false;
  }

  // Refill energy to max (called after watching a rewarded ad)
  Future<void> refillEnergy() async {
    _currentEnergy = maxEnergy;
    await _prefs.setInt(_energyKey, _currentEnergy);
  }
}