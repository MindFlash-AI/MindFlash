import 'package:shared_preferences/shared_preferences.dart';

class EnergyService {
  static const int maxEnergy = 15;
  static const String _energyKey = 'ai_energy_count';
  static const String _dateKey = 'ai_last_reset_date';

  int _currentEnergy = maxEnergy;

  // FIX 1: Track whether init() has completed. If any method is called before
  // init() returns, we await the same Future instead of running a second
  // getInstance() call or silently returning stale data.
  Future<void>? _initFuture;
  SharedPreferences? _prefs;

  int get currentEnergy => _currentEnergy;

  // FIX 1: init() is now idempotent — calling it multiple times (e.g. from
  // multiple widgets) only runs the setup logic once.
  Future<void> init() {
    _initFuture ??= _initialize();
    return _initFuture!;
  }

  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _checkDailyReset();
  }

  // FIX 2: Extracted guard so every public method can safely await init
  // before touching _prefs. This prevents a null crash if someone calls
  // deductEnergy() before the first init() completes.
  Future<SharedPreferences> _ensureReady() async {
    await init();
    return _prefs!;
  }

  void _checkDailyReset() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final String? lastReset = _prefs!.getString(_dateKey);

    if (lastReset != today) {
      _currentEnergy = maxEnergy;
      _prefs!.setInt(_energyKey, _currentEnergy);
      _prefs!.setString(_dateKey, today);
    } else {
      _currentEnergy = _prefs!.getInt(_energyKey) ?? maxEnergy;
    }
  }

  Future<bool> deductEnergy() async {
    final prefs = await _ensureReady();
    if (_currentEnergy <= 0) return false;
    _currentEnergy--;
    await prefs.setInt(_energyKey, _currentEnergy);
    return true;
  }

  Future<void> refillEnergy() async {
    final prefs = await _ensureReady();
    _currentEnergy = maxEnergy;
    await prefs.setInt(_energyKey, _currentEnergy);
  }
}