import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/database_sync_service.dart';
import '../services/api_service.dart';

class MealDataProvider with ChangeNotifier {
  // 주간 식단 데이터 (날짜별로 저장) - JSON 호환 타입으로 변경
  Map<String, dynamic> _weeklyMeals = <String, dynamic>{};
  
  // 업로드된 파일 목록
  List<String> _uploadedFiles = [];

  // Getters - 안전한 타입 변환
  Map<String, List<Map<String, dynamic>>> get weeklyMeals {
    final result = <String, List<Map<String, dynamic>>>{};
    for (final entry in _weeklyMeals.entries) {
      if (entry.value is List) {
        result[entry.key] = (entry.value as List).map((meal) {
          if (meal is Map) {
            return Map<String, dynamic>.from(meal);
          }
          return <String, dynamic>{};
        }).toList();
      }
    }
    return result;
  }
  
  List<String> get uploadedFiles => _uploadedFiles;

  // 초기화 - 저장된 데이터 로드 및 데이터베이스 동기화
  Future<void> initialize() async {
    await _loadMealData();
    // 샘플 데이터 자동 초기화
    await initializeSampleData();
    
    // 데이터베이스 자동 동기화
    await _syncWithDatabase();
  }

  // 데이터베이스와 동기화
  Future<void> _syncWithDatabase() async {
    try {
      final syncStatus = await DatabaseSyncService.getSyncStatus();
      if (syncStatus['is_online'] == true && syncStatus['sync_enabled'] == true) {
        print('🔄 식단 데이터 자동 동기화 시작...');
        await DatabaseSyncService.autoSync();
      }
    } catch (e) {
      print('⚠️ 식단 데이터 자동 동기화 실패: $e');
    }
  }

  // 저장된 식단 데이터 로드
  Future<void> _loadMealData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 주간 식단 데이터 로드
      final weeklyMealsJson = prefs.getString('weekly_meals');
      if (weeklyMealsJson != null) {
        final decoded = json.decode(weeklyMealsJson);
        if (decoded is Map) {
          _weeklyMeals = Map<String, dynamic>.from(decoded);
        }
      }
      
      // 업로드된 파일 목록 로드
      final uploadedFilesJson = prefs.getString('uploaded_files');
      if (uploadedFilesJson != null) {
        _uploadedFiles = List<String>.from(json.decode(uploadedFilesJson));
      }
      
      print('✅ 식단 데이터 로드 완료: ${_weeklyMeals.length}개 날짜, ${_uploadedFiles.length}개 파일');
      notifyListeners();
    } catch (e) {
      print('❌ 식단 데이터 로드 오류: $e');
      // 오류 발생 시 데이터 초기화
      _weeklyMeals.clear();
      _uploadedFiles.clear();
    }
  }

  // 식단 데이터 저장
  Future<void> _saveMealData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 주간 식단 데이터를 직접 JSON으로 인코딩 (이미 JSON 호환 타입)
      await prefs.setString('weekly_meals', json.encode(_weeklyMeals));
      
      // 업로드된 파일 목록 저장
      await prefs.setString('uploaded_files', json.encode(_uploadedFiles));
      
      print('✅ 식단 데이터 저장 완료');
    } catch (e) {
      print('❌ 식단 데이터 저장 오류: $e');
      // 저장 실패 시 기본 형태로 재시도
      try {
        final fallbackPrefs = await SharedPreferences.getInstance();
        final basicMeals = <String, dynamic>{};
        for (final entry in _weeklyMeals.entries) {
          basicMeals[entry.key] = <dynamic>[];
        }
        await fallbackPrefs.setString('weekly_meals', json.encode(basicMeals));
        print('✅ 기본 형태로 식단 데이터 저장 완료');
      } catch (fallbackError) {
        print('❌ 기본 형태 저장도 실패: $fallbackError');
      }
    }
  }

  // 특정 날짜의 식단 가져오기
  List<Map<String, dynamic>> getMealsForDate(String dateKey) {
    final meals = _weeklyMeals[dateKey];
    if (meals is List) {
      return meals.map((meal) {
        if (meal is Map) {
          return Map<String, dynamic>.from(meal);
        }
        return <String, dynamic>{};
      }).toList();
    }
    return [];
  }

  // 특정 날짜에 식단 추가 (데이터베이스 동기화 포함)
  Future<void> addMealToDate(String dateKey, Map<String, dynamic> meal) async {
    try {
      print('📅 MealDataProvider.addMealToDate 호출: $dateKey');
      print('🍽️ 추가할 식사 데이터: $meal');
      
      // 완전히 새로운 Map으로 안전한 데이터 생성
      final safeMeal = <String, dynamic>{
        'type': meal['type']?.toString() ?? '기타',
        'time': meal['time']?.toString() ?? '12:00',
        'foods': _convertToStringList(meal['foods']),
        'calories': _convertToInt(meal['calories']),
        'image': meal['image']?.toString() ?? 'default_meal.jpg',
      };
      
      // 추가 필드들도 안전하게 처리
      if (meal['nutrients'] != null) {
        safeMeal['nutrients'] = meal['nutrients'];
      }
      
      // 날짜 키가 없으면 새로 생성
      if (_weeklyMeals[dateKey] == null) {
        _weeklyMeals[dateKey] = <dynamic>[];
        print('📝 새로운 날짜 키 생성: $dateKey');
      }
      
      // 안전한 타입으로 추가
      final mealsList = _weeklyMeals[dateKey] as List<dynamic>;
      mealsList.add(safeMeal);
      print('📊 현재 $dateKey의 식사 개수: ${mealsList.length}');
      
      // 로컬 저장
      await _saveMealData();
      notifyListeners();
      
      // 데이터베이스에 실시간 저장 (비동기로 처리하여 UI 블로킹 방지)
      _saveMealToDatabase(dateKey, safeMeal).catchError((error) {
        print('⚠️ 데이터베이스 저장 실패 (로컬 저장은 완료됨): $error');
      });
      
      print('✅ 식단 추가 완료: $dateKey - ${safeMeal['type']} ${safeMeal['foods']}');
    } catch (e, stackTrace) {
      print('❌ 식단 추가 중 오류 발생: $e');
      print('❌ 스택 트레이스: $stackTrace');
      
      // 에러 발생 시에도 기본적인 복구 시도
      try {
        // 최소한의 기본 식사 데이터로 다시 시도
        final basicMeal = <String, dynamic>{
          'type': '기타',
          'time': '12:00',
          'foods': <String>['인식된 음식'],
          'calories': 0,
          'image': 'default_meal.jpg',
        };
        
        if (_weeklyMeals[dateKey] == null) {
          _weeklyMeals[dateKey] = <dynamic>[];
        }
        
        final mealsList = _weeklyMeals[dateKey] as List<dynamic>;
        mealsList.add(basicMeal);
        await _saveMealData();
        notifyListeners();
        
        print('✅ 기본 식사 데이터로 복구 성공');
      } catch (recoveryError) {
        print('❌ 복구 시도도 실패: $recoveryError');
        rethrow; // 복구도 실패하면 원래 에러를 다시 던짐
      }
    }
  }

  // 안전한 문자열 리스트 변환
  List<String> _convertToStringList(dynamic value) {
    if (value == null) return <String>[];
    if (value is List<String>) return value;
    if (value is List) {
      return value.map((item) => item?.toString() ?? '').where((item) => item.isNotEmpty).toList();
    }
    return <String>[];
  }

  // 안전한 정수 변환
  int _convertToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  // 데이터베이스에 식사 기록 저장
  Future<void> _saveMealToDatabase(String dateKey, Map<String, dynamic> meal) async {
    try {
      final userId = await DatabaseSyncService.getCurrentUserId();
      if (userId != null && !userId.startsWith('temp_')) {
        final syncStatus = await DatabaseSyncService.getSyncStatus();
        if (syncStatus['sync_enabled'] == true) {
          await ApiService.saveMealRecord(
            userId: userId,
            date: dateKey,
            mealType: meal['type'] ?? '기타',
            foods: List<String>.from(meal['foods'] ?? []),
            nutrients: meal['nutrients'] ?? {},
            calories: (meal['calories'] ?? 0).toDouble(),
            imagePath: meal['image'],
            aiAnalysis: meal,
          );
          print('✅ 식사 기록 데이터베이스 저장 완료');
        }
      }
    } catch (e) {
      print('⚠️ 식사 기록 데이터베이스 저장 실패: $e');
    }
  }

  // 특정 날짜의 식단 삭제
  Future<void> removeMealFromDate(String dateKey, int mealIndex) async {
    final meals = _weeklyMeals[dateKey];
    if (meals is List && mealIndex < meals.length) {
      final removedMeal = meals.removeAt(mealIndex);
      
      // 빈 날짜는 제거
      if (meals.isEmpty) {
        _weeklyMeals.remove(dateKey);
      }
      
      await _saveMealData();
      notifyListeners();
      
      print('✅ 식단 삭제: $dateKey - ${removedMeal is Map ? removedMeal['type'] : '알 수 없음'}');
    }
  }

  // 업로드된 파일 추가
  Future<void> addUploadedFile(String fileName) async {
    if (!_uploadedFiles.contains(fileName)) {
      _uploadedFiles.add(fileName);
      await _saveMealData();
      notifyListeners();
      
      print('✅ 파일 추가: $fileName');
    }
  }

  // 업로드된 파일 삭제
  Future<void> removeUploadedFile(String fileName) async {
    _uploadedFiles.remove(fileName);
    await _saveMealData();
    notifyListeners();
    
    print('✅ 파일 삭제: $fileName');
  }

  // 특정 날짜의 총 칼로리 계산
  int getTotalCaloriesForDate(String dateKey) {
    final meals = getMealsForDate(dateKey);
    return meals.fold(0, (total, meal) => total + (meal['calories'] as int? ?? 0));
  }

  // 특정 날짜에 특정 타입의 식사가 있는지 확인
  bool hasMealTypeForDate(String dateKey, String mealType) {
    final meals = getMealsForDate(dateKey);
    return meals.any((meal) => meal['type'] == mealType);
  }

  // 샘플 데이터 초기화 (처음 사용 시)
  Future<void> initializeSampleData() async {
    // 항상 샘플 데이터를 로드하도록 수정 (테스트용)
    final sampleMeals = <String, dynamic>{
        '2026-01-20': <dynamic>[
          <String, dynamic>{
            'type': '아침',
            'time': '08:30',
            'foods': <String>['현미밥', '된장찌개', '김치', '계란후라이'],
            'image': 'breakfast_1.jpg',
            'calories': 450,
          },
          <String, dynamic>{
            'type': '점심',
            'time': '12:30',
            'foods': <String>['불고기덮밥', '미역국', '나물반찬'],
            'image': 'lunch_1.jpg',
            'calories': 680,
          },
          <String, dynamic>{
            'type': '저녁',
            'time': '19:00',
            'foods': <String>['연어구이', '샐러드', '현미밥'],
            'image': 'dinner_1.jpg',
            'calories': 520,
          },
        ],
        '2026-01-21': <dynamic>[
          <String, dynamic>{
            'type': '아침',
            'time': '08:00',
            'foods': <String>['오트밀', '바나나', '견과류'],
            'image': 'breakfast_2.jpg',
            'calories': 380,
          },
          <String, dynamic>{
            'type': '점심',
            'time': '13:00',
            'foods': <String>['치킨샐러드', '통밀빵', '요거트'],
            'image': 'lunch_2.jpg',
            'calories': 550,
          },
        ],
        '2026-01-22': <dynamic>[
          <String, dynamic>{
            'type': '아침',
            'time': '08:15',
            'foods': <String>['토스트', '아보카도', '스크램블에그'],
            'image': 'breakfast_3.jpg',
            'calories': 420,
          },
          <String, dynamic>{
            'type': '점심',
            'time': '12:45',
            'foods': <String>['비빔밥', '된장국', '김치'],
            'image': 'lunch_3.jpg',
            'calories': 600,
          },
          <String, dynamic>{
            'type': '저녁',
            'time': '18:30',
            'foods': <String>['닭가슴살', '브로콜리', '고구마'],
            'image': 'dinner_3.jpg',
            'calories': 480,
          },
        ],
        '2026-01-28': <dynamic>[
          <String, dynamic>{
            'type': '아침',
            'time': '08:00',
            'foods': <String>['현미밥', '된장찌개', '김치', '계란'],
            'image': 'breakfast_today.jpg',
            'calories': 450,
          },
          <String, dynamic>{
            'type': '점심',
            'time': '12:30',
            'foods': <String>['연어구이', '샐러드', '현미밥', '우유'],
            'image': 'lunch_today.jpg',
            'calories': 620,
          },
          <String, dynamic>{
            'type': '저녁',
            'time': '19:00',
            'foods': <String>['닭가슴살', '브로콜리', '견과류', '요거트'],
            'image': 'dinner_today.jpg',
            'calories': 540,
          },
        ],
      };

      _weeklyMeals = sampleMeals;
      await _saveMealData();
      notifyListeners();
      
      print('✅ 샘플 식단 데이터 초기화 완료');
  }

  // 모든 식단 데이터 삭제
  Future<void> clearAllMealData() async {
    _weeklyMeals.clear();
    _uploadedFiles.clear();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('weekly_meals');
    await prefs.remove('uploaded_files');
    
    notifyListeners();
    print('✅ 모든 식단 데이터 삭제 완료');
  }

  // 오래된 데이터 정리 (30일 이전 데이터 삭제)
  Future<void> cleanupOldData() async {
    final now = DateTime.now();
    final cutoffDate = now.subtract(const Duration(days: 30));
    
    final keysToRemove = <String>[];
    
    for (final dateKey in _weeklyMeals.keys) {
      try {
        final date = DateTime.parse(dateKey);
        if (date.isBefore(cutoffDate)) {
          keysToRemove.add(dateKey);
        }
      } catch (e) {
        // 잘못된 날짜 형식은 삭제
        keysToRemove.add(dateKey);
      }
    }
    
    for (final key in keysToRemove) {
      _weeklyMeals.remove(key);
    }
    
    if (keysToRemove.isNotEmpty) {
      await _saveMealData();
      notifyListeners();
      print('✅ 오래된 식단 데이터 ${keysToRemove.length}개 정리 완료');
    }
  }

  // 데이터 통계 (데이터베이스 연동)
  Map<String, int> getDataStatistics() {
    int totalMeals = 0;
    int totalDays = _weeklyMeals.length;
    
    for (final meals in _weeklyMeals.values) {
      totalMeals += meals.length as int;
    }
    
    return {
      'totalDays': totalDays,
      'totalMeals': totalMeals,
      'uploadedFiles': _uploadedFiles.length,
    };
  }

  // 서버에서 식사 데이터 동기화
  Future<void> syncMealsFromServer() async {
    try {
      final userId = await DatabaseSyncService.getCurrentUserId();
      if (userId == null || userId.startsWith('temp_')) {
        print('⚠️ 오프라인 모드 - 서버 동기화 불가');
        return;
      }

      final syncStatus = await DatabaseSyncService.getSyncStatus();
      if (syncStatus['sync_enabled'] != true) {
        print('⚠️ 동기화가 비활성화됨');
        return;
      }

      print('🔄 서버에서 식사 데이터 동기화 시작...');

      // 최근 7일간의 데이터 가져오기
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 7));
      final endDate = now;

      final response = await ApiService.getMealRecords(
        userId: userId,
        startDate: '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
        endDate: '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
      );

      if (response['success'] == true) {
        final meals = response['meals'] as List;
        
        // 서버 데이터를 로컬 형식으로 변환
        for (var meal in meals) {
          final dateKey = meal['date'];
          final mealData = {
            'type': meal['meal_type'],
            'time': '12:00', // 기본값
            'foods': List<String>.from(meal['foods']),
            'image': meal['image_path'] ?? 'server_meal.jpg',
            'calories': (meal['calories'] ?? 0).toInt(),
            'nutrients': meal['nutrients'] ?? {},
          };

          // 중복 확인 후 추가
          if (!_isDuplicateMeal(dateKey, mealData)) {
            if (_weeklyMeals[dateKey] == null) {
              _weeklyMeals[dateKey] = [];
            }
            _weeklyMeals[dateKey]!.add(mealData);
          }
        }

        await _saveMealData();
        notifyListeners();
        print('✅ 서버 식사 데이터 동기화 완료: ${meals.length}개');
      }
    } catch (e) {
      print('❌ 서버 식사 데이터 동기화 실패: $e');
    }
  }

  // 중복 식사 확인
  bool _isDuplicateMeal(String dateKey, Map<String, dynamic> newMeal) {
    final existingMeals = _weeklyMeals[dateKey] ?? [];
    
    for (var meal in existingMeals) {
      if (meal['type'] == newMeal['type'] && 
          _listsEqual(meal['foods'], newMeal['foods'])) {
        return true;
      }
    }
    return false;
  }

  // 리스트 비교 헬퍼
  bool _listsEqual(List<dynamic> list1, List<dynamic> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  // 전체 동기화 (양방향)
  Future<Map<String, dynamic>> fullSync() async {
    try {
      print('🔄 식사 데이터 전체 동기화 시작...');
      
      // 1. 서버에서 데이터 가져오기
      await syncMealsFromServer();
      
      // 2. 로컬 데이터를 서버로 전송 (DatabaseSyncService 사용)
      final syncResult = await DatabaseSyncService.syncLocalToServer();
      
      return {
        'success': true,
        'message': '식사 데이터 전체 동기화 완료',
        'sync_result': syncResult,
      };
    } catch (e) {
      print('❌ 식사 데이터 전체 동기화 실패: $e');
      return {
        'success': false,
        'message': '식사 데이터 동기화 실패: $e',
      };
    }
  }
}