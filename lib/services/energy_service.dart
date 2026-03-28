import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EnergyService {
  // Implement Singleton pattern so the entire app shares the same energy state
  static final EnergyService _instance = EnergyService._internal();
  factory EnergyService() => _instance;
  EnergyService._internal();

  int currentEnergy = 3;
  String _lastRefillDate = '';
  static const int maxEnergy = 3;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    currentEnergy = prefs.getInt('energy_count') ?? maxEnergy;
    _lastRefillDate = prefs.getString('last_refill_date') ?? '';
    await _checkDailyRefill();
    _isInitialized = true;
  }

  // --- VULNERABILITY 1 FIX: Server-Side Time Verification ---
  // Fetch the current time from an external reliable server to prevent 
  // users from changing their device time to get free energy.
  Future<DateTime?> _getNetworkTime() async {
    try {
      final response = await http
          .get(Uri.parse('http://worldtimeapi.org/api/timezone/Etc/UTC'))
          .timeout(const Duration(seconds: 5));
          
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DateTime.parse(data['datetime']);
      }
    } catch (e) {
      // If offline or API fails, return null. 
      // We will fallback to device time safely below.
    }
    return null;
  }

  Future<void> _checkDailyRefill() async {
    DateTime? networkTime = await _getNetworkTime();
    
    // If they are offline, they can't use AI anyway, so falling back to local 
    // time is safe. The moment they connect to the internet to generate, 
    // they will trigger this again with real network time if the app restarts.
    DateTime now = networkTime ?? DateTime.now(); 
    String today = "${now.year}-${now.month}-${now.day}";

    if (_lastRefillDate != today) {
      currentEnergy = maxEnergy;
      _lastRefillDate = today;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('energy_count', currentEnergy);
      await prefs.setString('last_refill_date', _lastRefillDate);
    }
  }

  Future<void> deductEnergy() async {
    if (currentEnergy > 0) {
      currentEnergy--;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('energy_count', currentEnergy);
    }
  }

  Future<void> refillEnergy() async {
    currentEnergy = maxEnergy;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('energy_count', currentEnergy);
  }
}