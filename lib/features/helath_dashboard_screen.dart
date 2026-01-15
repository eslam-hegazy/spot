import 'dart:async';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'health_service.dart';

class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  _HealthDashboardScreenState createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  final HealthService _service = HealthService();
  Map<HealthDataType, String> latestValues = {};
  Timer? _timer;

  /// Important types to show live
  final List<HealthDataType> importantTypes = [
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.BODY_TEMPERATURE,
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  @override
  void initState() {
    super.initState();
    _loadCachedData();
    _loadData(); // initial load
    // Live update every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _loadData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Load cached values first
  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    Map<HealthDataType, String> cache = {};
    for (var type in importantTypes) {
      final value = prefs.getString(type.name);
      if (value != null) cache[type] = value;
    }
    if (cache.isNotEmpty) {
      setState(() => latestValues = cache);
    }
  }

  /// Load today's health data
  Future<void> _loadData() async {
    final newData = await _service.fetchTodayData();
    Map<HealthDataType, String> filteredData = {};
    for (var type in importantTypes) {
      filteredData[type] =
          newData[type] ?? "0 ${_service.typeUnits[type] ?? ""}";
    }
    setState(() => latestValues = filteredData);
    _saveToCache(filteredData);
  }

  /// Save to SharedPreferences cache
  Future<void> _saveToCache(Map<HealthDataType, String> data) async {
    final prefs = await SharedPreferences.getInstance();
    for (var entry in data.entries) {
      await prefs.setString(entry.key.name, entry.value);
    }
  }

  /// Icons for each type
  IconData iconForType(HealthDataType type) {
    switch (type) {
      case HealthDataType.HEART_RATE:
      case HealthDataType.RESTING_HEART_RATE:
        return Icons.favorite;
      case HealthDataType.STEPS:
        return Icons.directions_walk;
      case HealthDataType.ACTIVE_ENERGY_BURNED:
        return Icons.local_fire_department;
      case HealthDataType.WEIGHT:
      case HealthDataType.BODY_MASS_INDEX:
      case HealthDataType.LEAN_BODY_MASS:
        return Icons.fitness_center;
      case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
      case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
        return Icons.monitor_heart;
      case HealthDataType.BLOOD_OXYGEN:
        return Icons.bloodtype;
      case HealthDataType.BLOOD_GLUCOSE:
        return Icons.invert_colors;
      case HealthDataType.BODY_TEMPERATURE:
        return Icons.thermostat;
      default:
        return Icons.health_and_safety;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Health Dashboard")),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: importantTypes.length,
        itemBuilder: (context, index) {
          final type = importantTypes[index];
          final value =
              latestValues[type] ?? "0 ${_service.typeUnits[type] ?? ""}";

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(iconForType(type), size: 40, color: Colors.blue),
                  const SizedBox(height: 12),
                  Text(
                    type.name.replaceAll('_', ' ').toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value.replaceAll('NumericHealthValue - numericValue:', ""),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
