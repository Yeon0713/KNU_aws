import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Medication {
  final String id;
  final String name;
  final String time;

  Medication({
    required this.id,
    required this.name,
    required this.time,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'time': time,
    };
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      name: json['name'],
      time: json['time'],
    );
  }
}

class DayMedications {
  final List<Medication> medications;
  final List<String> completed;

  DayMedications({
    required this.medications,
    required this.completed,
  });

  DayMedications copyWith({
    List<Medication>? medications,
    List<String>? completed,
  }) {
    return DayMedications(
      medications: medications ?? this.medications,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medications': medications.map((med) => med.toJson()).toList(),
      'completed': completed,
    };
  }

  factory DayMedications.fromJson(Map<String, dynamic> json) {
    return DayMedications(
      medications: (json['medications'] as List<dynamic>)
          .map((med) => Medication.fromJson(med))
          .toList(),
      completed: List<String>.from(json['completed']),
    );
  }
}

class MedicationProvider with ChangeNotifier {
  Map<String, DayMedications> _medicationData = {};
  DateTime _currentWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday % 7));
  String _selectedDate = DateTime.now().toIso8601String().split('T')[0];

  final List<Medication> _initialMedications = [
    Medication(id: '1', name: '오메가3', time: '아침'),
    Medication(id: '2', name: '비타민D', time: '아침'),
    Medication(id: '3', name: '칼슘', time: '저녁'),
    Medication(id: '4', name: '유산균', time: '아침'),
  ];

  Map<String, DayMedications> get medicationData => _medicationData;
  DateTime get currentWeekStart => _currentWeekStart;
  String get selectedDate => _selectedDate;

  Future<void> initialize() async {
    await _loadMedicationData();
  }

  void setSelectedDate(String date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setCurrentWeekStart(DateTime weekStart) {
    _currentWeekStart = weekStart;
    _initializeMedicationData();
    notifyListeners();
  }

  Future<void> _loadMedicationData() async {
    final prefs = await SharedPreferences.getInstance();
    final medicationDataString = prefs.getString('medicationData');
    
    if (medicationDataString != null) {
      try {
        final Map<String, dynamic> savedData = json.decode(medicationDataString);
        _medicationData = savedData.map((key, value) => MapEntry(
          key,
          DayMedications.fromJson(value),
        ));
      } catch (e) {
        print('복약 데이터 로드 오류: $e');
        _initializeMedicationData();
      }
    } else {
      _initializeMedicationData();
    }
    notifyListeners();
  }

  void _initializeMedicationData() {
    for (int i = 0; i < 7; i++) {
      final date = _currentWeekStart.add(Duration(days: i));
      final dateKey = date.toIso8601String().split('T')[0];
      if (!_medicationData.containsKey(dateKey)) {
        _medicationData[dateKey] = DayMedications(
          medications: _initialMedications,
          completed: [],
        );
      }
    }
    _saveMedicationData();
  }

  Future<void> _saveMedicationData() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> dataToSave = _medicationData.map((key, value) => MapEntry(
      key,
      value.toJson(),
    ));
    await prefs.setString('medicationData', json.encode(dataToSave));
  }

  void toggleMedicationComplete(String medicationId) {
    final dayData = _medicationData[_selectedDate];
    if (dayData != null) {
      final isCompleted = dayData.completed.contains(medicationId);
      
      _medicationData[_selectedDate] = dayData.copyWith(
        completed: isCompleted
            ? dayData.completed.where((id) => id != medicationId).toList()
            : [...dayData.completed, medicationId],
      );
      
      _saveMedicationData();
      notifyListeners();
    }
  }

  DayMedications? getDayMedications(String date) {
    return _medicationData[date];
  }

  void previousWeek() {
    _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    _initializeMedicationData();
    notifyListeners();
  }

  void nextWeek() {
    _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    _initializeMedicationData();
    notifyListeners();
  }
}