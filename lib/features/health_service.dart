import 'dart:io';

import 'package:health/health.dart';
import 'package:spot/features/utils.dart';

class HealthService {
  final Health _health = Health();

  /// Units for each type
  final Map<HealthDataType, String> typeUnits = {
    HealthDataType.HEART_RATE: "bpm",
    HealthDataType.RESTING_HEART_RATE: "bpm",
    HealthDataType.STEPS: "steps",
    HealthDataType.WEIGHT: "kg",
    HealthDataType.BODY_MASS_INDEX: "BMI",
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC: "mmHg",
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC: "mmHg",
    HealthDataType.BLOOD_OXYGEN: "%",
    HealthDataType.BLOOD_GLUCOSE: "mg/dL",
    HealthDataType.SLEEP_ASLEEP: "h",
    HealthDataType.SLEEP_AWAKE: "h",
    HealthDataType.DISTANCE_WALKING_RUNNING: "m",
    HealthDataType.ACTIVE_ENERGY_BURNED: "kcal",
    HealthDataType.BASAL_ENERGY_BURNED: "kcal",
    HealthDataType.WATER: "ml",
    HealthDataType.HEIGHT: "cm",
    HealthDataType.MINDFULNESS: "min",
    HealthDataType.WAIST_CIRCUMFERENCE: "cm",
    HealthDataType.LEAN_BODY_MASS: "kg",
    HealthDataType.BODY_TEMPERATURE: "°C",
  };

  /// All data types depending on platform
  List<HealthDataType> get allTypes =>
      Platform.isAndroid ? dataTypesAndroid : dataTypesIOS;

  /// Fetch only today's data for important metrics
  Future<Map<HealthDataType, String>> fetchTodayData() async {
    final Map<HealthDataType, String> latestValues = {};
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    for (var type in allTypes) {
      try {
        bool granted = await _health.requestAuthorization([type]);
        if (!granted) {
          latestValues[type] = "Access Denied";
          continue;
        }

        final data = await _health.getHealthDataFromTypes(
          types: [type],
          startTime: startOfDay,
          endTime: now,
        );

        if (data.isNotEmpty) {
          data.sort((a, b) => b.dateTo.compareTo(a.dateTo));
          final value = data.first.value.toString();
          final unit = typeUnits[type] ?? "";
          latestValues[type] = "$value $unit";
        } else {
          latestValues[type] = "0 ${typeUnits[type] ?? ""}";
        }
      } catch (e) {
        latestValues[type] = "Error";
      }
    }

    return latestValues;
  }
}
