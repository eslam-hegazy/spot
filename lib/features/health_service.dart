import 'dart:io';

import 'package:health/health.dart';
import 'package:spot/features/utils.dart';

class HealthService {
  final Health _health = Health();
  bool _permissionGranted = false;

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

  List<HealthDataType> get allTypes =>
      Platform.isAndroid ? dataTypesAndroid : dataTypesIOS;

  void _log(String msg) {
    // ignore: avoid_print
    print("[HealthService] $msg");
  }

  /// Permission (only once)
  Future<bool> requestPermissionsOnce() async {
    if (_permissionGranted) {
      _log("Permissions already granted");
      return true;
    }

    _log("Requesting permissions for ${allTypes.length} types");

    final granted = await _health.requestAuthorization(
      allTypes,
      permissions: allTypes.map((_) => HealthDataAccess.READ).toList(),
    );

    _permissionGranted = granted;
    _log("Permission result: $granted");

    return granted;
  }

  /// Fetch today's data
  Future<Map<HealthDataType, String>> fetchTodayData() async {
    final Map<HealthDataType, String> latestValues = {};

    _log("Fetching today's health data...");

    final granted = await requestPermissionsOnce();
    if (!granted) {
      _log("Permission denied — returning empty map");
      return latestValues;
    }

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);

    /// STEPS
    try {
      final steps = await _health.getTotalStepsInInterval(start, now);
      _log("STEPS: ${steps ?? 0}");
      latestValues[HealthDataType.STEPS] =
      "${steps ?? 0} ${typeUnits[HealthDataType.STEPS]}";
    } catch (e) {
      _log("STEPS error: $e");
    }

    /// OTHER TYPES
    for (final type in allTypes) {
      if (type == HealthDataType.STEPS) continue;

      try {
        _log("Reading $type");

        final data = await _health.getHealthDataFromTypes(
          types: [type],
          startTime: start,
          endTime: now,
        );

        if (data.isEmpty) {
          _log("→ $type: no data");
          continue;
        }

        data.sort((a, b) => b.dateTo.compareTo(a.dateTo));
        final rawValue = data.first.value;
        final parsed = _safeValue(rawValue);

        _log(
          "→ $type: "
              "count=${data.length}, "
              "raw=$rawValue, "
              "parsed=$parsed",
        );

        latestValues[type] =
        "$parsed ${typeUnits[type] ?? ""}";
      } catch (e) {
        _log("→ $type ERROR: $e");
      }
    }

    _log("Finished fetching data. Returned ${latestValues.length} values");
    return latestValues;
  }

  String _safeValue(dynamic value) {
    if (value is num) return value.toStringAsFixed(1);

    final text = value.toString();
    final match = RegExp(r'([\d.]+)').firstMatch(text);
    return match?.group(1) ?? text;
  }
}
