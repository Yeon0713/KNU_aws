import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'api_service.dart';
import 'data_storage_service.dart';

class DatabaseSyncService {
  static const String _userIdKey = 'user_id';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _syncEnabledKey = 'sync_enabled';
  
  // 사용자 ID 관리
  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }
  
  static Future<void> setCurrentUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    print('✅ 사용자 ID 저장: $userId');
  }
  
  static Future<void> clearCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    print('✅ 사용자 ID 삭제');
  }
  
  // 동기화 설정 관리
  static Future<bool> isSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_syncEnabledKey) ?? true; // 기본값: 활성화
  }
  
  static Future<void> setSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncEnabledKey, enabled);
    print('✅ 동기화 설정 변경: $enabled');
  }
  
  // 마지막 동기화 시간 관리
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastSyncKey);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }
  
  static Future<void> setLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, time.toIso8601String());
  }
  
  // 사용자 생성 또는 로그인
  static Future<String> createOrGetUser({
    required String name,
    required int age,
    required String gender,
    required double height,
    required double weight,
    List<String> healthConcerns = const [],
  }) async {
    try {
      // 기존 사용자 ID 확인
      String? existingUserId = await getCurrentUserId();
      
      if (existingUserId != null) {
        // 기존 사용자 정보 확인
        try {
          final userResponse = await ApiService.getUser(existingUserId);
          if (userResponse['success'] == true) {
            print('✅ 기존 사용자 로그인: $existingUserId');
            return existingUserId;
          }
        } catch (e) {
          print('⚠️ 기존 사용자 정보 조회 실패, 새 사용자 생성: $e');
        }
      }
      
      // 새 사용자 생성
      final response = await ApiService.createUser(
        name: name,
        age: age,
        gender: gender,
        height: height,
        weight: weight,
        healthConcerns: healthConcerns,
      );
      
      if (response['success'] == true) {
        final userId = response['user_id'];
        await setCurrentUserId(userId);
        print('✅ 새 사용자 생성 및 로그인: $userId');
        return userId;
      } else {
        throw Exception('사용자 생성 실패');
      }
    } catch (e) {
      print('❌ 사용자 생성/로그인 오류: $e');
      
      // 오프라인 모드: 임시 사용자 ID 생성
      String tempUserId = 'temp_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
      await setCurrentUserId(tempUserId);
      print('⚠️ 오프라인 모드: 임시 사용자 ID 생성 $tempUserId');
      return tempUserId;
    }
  }
  
  // 로컬 데이터를 서버로 동기화
  static Future<Map<String, dynamic>> syncLocalToServer() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        throw Exception('사용자 ID가 없습니다. 먼저 로그인하세요.');
      }
      
      if (userId.startsWith('temp_')) {
        print('⚠️ 임시 사용자 ID로는 서버 동기화를 할 수 없습니다.');
        return {'success': false, 'message': '오프라인 모드입니다.'};
      }
      
      final syncEnabled = await isSyncEnabled();
      if (!syncEnabled) {
        print('⚠️ 동기화가 비활성화되어 있습니다.');
        return {'success': false, 'message': '동기화가 비활성화되어 있습니다.'};
      }
      
      print('🔄 로컬 데이터를 서버로 동기화 시작...');
      
      // 로컬 데이터 수집
      final mealHistory = await DataStorageService.getMealAnalysisHistory();
      final supplementHistory = await DataStorageService.getSupplementAnalysisHistory();
      final checkupHistory = await DataStorageService.getCheckupAnalysisHistory();
      final factCheckHistory = await DataStorageService.getFactCheckHistory();
      
      // 서버 형식으로 변환
      List<Map<String, dynamic>> meals = [];
      List<Map<String, dynamic>> supplementAnalyses = [];
      List<Map<String, dynamic>> healthCheckups = [];
      List<Map<String, dynamic>> factChecks = [];
      
      // 식사 데이터 변환
      for (var meal in mealHistory) {
        final data = meal['data'] as Map<String, dynamic>;
        final timestamp = meal['timestamp'] as String;
        final date = DateTime.parse(timestamp);
        
        meals.add({
          'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          'meal_type': data['meal_type'] ?? '기타',
          'foods': data['detected_foods'] ?? [],
          'nutrients': data['nutrients'] ?? {},
          'calories': data['calories'] ?? 0,
          'image_path': meal['imagePath'],
          'ai_analysis': data,
        });
      }
      
      // 영양제 분석 데이터 변환
      for (var analysis in supplementHistory) {
        final data = analysis['data'] as Map<String, dynamic>;
        
        supplementAnalyses.add({
          'analysis_result': data,
          'recommended_supplements': data['supplement_list'] ?? [],
          'deficient_nutrients': data['deficient_nutrients'] ?? [],
        });
      }
      
      // 건강검진 데이터 변환
      for (var checkup in checkupHistory) {
        final data = checkup['data'] as Map<String, dynamic>;
        final timestamp = checkup['timestamp'] as String;
        final date = DateTime.parse(timestamp);
        
        healthCheckups.add({
          'checkup_date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          'checkup_data': data['checkup_data'] ?? {},
          'ai_analysis': data,
          'status': data['status'] ?? '',
          'image_path': checkup['imagePath'],
        });
      }
      
      // 팩트체크 데이터 변환
      for (var factCheck in factCheckHistory) {
        final data = factCheck['data'] as Map<String, dynamic>;
        
        factChecks.add({
          'query': factCheck['query'] ?? '',
          'source_type': data['source_type'] ?? 'text',
          'credibility_score': _parseCredibilityScore(data['overall_credibility']),
          'fact_check_result': data,
        });
      }
      
      // 서버로 동기화
      final syncResponse = await ApiService.syncUserData(
        userId: userId,
        meals: meals,
        supplementAnalyses: supplementAnalyses,
        healthCheckups: healthCheckups,
        factChecks: factChecks,
      );
      
      if (syncResponse['success'] == true) {
        await setLastSyncTime(DateTime.now());
        print('✅ 서버 동기화 완료: ${syncResponse['sync_result']}');
        return {
          'success': true,
          'message': '서버 동기화 완료',
          'sync_result': syncResponse['sync_result'],
        };
      } else {
        throw Exception('서버 동기화 실패');
      }
    } catch (e) {
      print('❌ 서버 동기화 오류: $e');
      return {
        'success': false,
        'message': '서버 동기화 실패: $e',
      };
    }
  }
  
  // 서버 데이터를 로컬로 동기화
  static Future<Map<String, dynamic>> syncServerToLocal() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        throw Exception('사용자 ID가 없습니다. 먼저 로그인하세요.');
      }
      
      if (userId.startsWith('temp_')) {
        print('⚠️ 임시 사용자 ID로는 서버에서 데이터를 가져올 수 없습니다.');
        return {'success': false, 'message': '오프라인 모드입니다.'};
      }
      
      print('🔄 서버 데이터를 로컬로 동기화 시작...');
      
      int syncedCount = 0;
      
      // 최신 영양제 분석 가져오기
      try {
        final supplementResponse = await ApiService.getLatestSupplementAnalysis(userId);
        if (supplementResponse['success'] == true && supplementResponse['analysis'] != null) {
          final analysis = supplementResponse['analysis'];
          await DataStorageService.saveSupplementAnalysis(analysis['analysis_result']);
          syncedCount++;
          print('✅ 영양제 분석 동기화 완료');
        }
      } catch (e) {
        print('⚠️ 영양제 분석 동기화 실패: $e');
      }
      
      // 최신 건강검진 가져오기
      try {
        final checkupResponse = await ApiService.getLatestHealthCheckup(userId);
        if (checkupResponse['success'] == true && checkupResponse['checkup'] != null) {
          final checkup = checkupResponse['checkup'];
          await DataStorageService.saveCheckupAnalysis(
            checkup['ai_analysis'], 
            checkup['image_path']
          );
          syncedCount++;
          print('✅ 건강검진 동기화 완료');
        }
      } catch (e) {
        print('⚠️ 건강검진 동기화 실패: $e');
      }
      
      // 팩트체크 기록 가져오기
      try {
        final factCheckResponse = await ApiService.getFactCheckHistory(userId, limit: 10);
        if (factCheckResponse['success'] == true) {
          final factChecks = factCheckResponse['fact_checks'] as List;
          for (var factCheck in factChecks) {
            await DataStorageService.saveFactCheckResult(
              factCheck['fact_check_result'],
              factCheck['query']
            );
            syncedCount++;
          }
          print('✅ 팩트체크 기록 동기화 완료: ${factChecks.length}개');
        }
      } catch (e) {
        print('⚠️ 팩트체크 기록 동기화 실패: $e');
      }
      
      await setLastSyncTime(DateTime.now());
      
      return {
        'success': true,
        'message': '로컬 동기화 완료',
        'synced_count': syncedCount,
      };
    } catch (e) {
      print('❌ 로컬 동기화 오류: $e');
      return {
        'success': false,
        'message': '로컬 동기화 실패: $e',
      };
    }
  }
  
  // 양방향 동기화
  static Future<Map<String, dynamic>> fullSync() async {
    try {
      print('🔄 전체 동기화 시작...');
      
      // 1. 로컬 → 서버
      final localToServerResult = await syncLocalToServer();
      
      // 2. 서버 → 로컬
      final serverToLocalResult = await syncServerToLocal();
      
      final success = localToServerResult['success'] && serverToLocalResult['success'];
      
      return {
        'success': success,
        'message': success ? '전체 동기화 완료' : '일부 동기화 실패',
        'local_to_server': localToServerResult,
        'server_to_local': serverToLocalResult,
      };
    } catch (e) {
      print('❌ 전체 동기화 오류: $e');
      return {
        'success': false,
        'message': '전체 동기화 실패: $e',
      };
    }
  }
  
  // 자동 동기화 (앱 시작 시 또는 주기적으로)
  static Future<void> autoSync() async {
    try {
      final syncEnabled = await isSyncEnabled();
      if (!syncEnabled) {
        print('⚠️ 자동 동기화가 비활성화되어 있습니다.');
        return;
      }
      
      // 사용자 ID 확인
      final userId = await getCurrentUserId();
      if (userId == null) {
        print('⚠️ 사용자 ID가 없어 자동 동기화를 건너뜁니다.');
        return;
      }
      
      if (userId.startsWith('temp_')) {
        print('⚠️ 임시 사용자 ID로 자동 동기화를 건너뜁니다.');
        return;
      }
      
      final lastSync = await getLastSyncTime();
      final now = DateTime.now();
      
      // 마지막 동기화로부터 1시간 이상 지났으면 자동 동기화
      if (lastSync == null || now.difference(lastSync).inHours >= 1) {
        print('🔄 자동 동기화 시작...');
        await fullSync();
      } else {
        print('⏰ 자동 동기화 스킵 (최근에 동기화됨)');
      }
    } catch (e) {
      print('❌ 자동 동기화 오류: $e');
    }
  }
  
  // 실시간 데이터 저장 (로컬 + 서버)
  static Future<void> saveAnalysisResult({
    required String type, // 'meal', 'supplement', 'checkup', 'factcheck'
    required Map<String, dynamic> result,
    String? imagePath,
    String? query,
  }) async {
    try {
      // 1. 로컬 저장 (기존 방식) - 무한 루프 방지를 위해 직접 저장
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().toIso8601String();
      
      switch (type) {
        case 'meal':
          final existingResults = await DataStorageService.getMealAnalysisHistory();
          final newResult = {
            'timestamp': timestamp,
            'data': result,
            'imagePath': imagePath,
          };
          existingResults.insert(0, newResult);
          if (existingResults.length > 20) {
            existingResults.removeRange(20, existingResults.length);
          }
          await prefs.setString('meal_analysis_history', json.encode(existingResults));
          break;
        case 'supplement':
          await DataStorageService.saveSupplementAnalysis(result);
          break;
        case 'checkup':
          await DataStorageService.saveCheckupAnalysis(result, imagePath);
          break;
        case 'factcheck':
          await DataStorageService.saveFactCheckResult(result, query ?? '');
          break;
      }
      
      // 2. 서버 저장 (동기화 활성화 시)
      final syncEnabled = await isSyncEnabled();
      final userId = await getCurrentUserId();
      
      if (syncEnabled && userId != null && !userId.startsWith('temp_')) {
        try {
          switch (type) {
            case 'supplement':
              await ApiService.saveSupplementAnalysis(
                userId: userId,
                analysisResult: result,
                recommendedSupplements: result['supplement_list'] ?? [],
                deficientNutrients: result['deficient_nutrients'] ?? [],
              );
              break;
            case 'checkup':
              final now = DateTime.now();
              await ApiService.saveHealthCheckup(
                userId: userId,
                checkupDate: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
                checkupData: result['checkup_data'] ?? {},
                aiAnalysis: result,
                status: result['status'] ?? '',
                imagePath: imagePath,
              );
              break;
            case 'factcheck':
              await ApiService.saveFactCheck(
                userId: userId,
                query: query ?? '',
                sourceType: result['source_type'] ?? 'text',
                credibilityScore: _parseCredibilityScore(result['overall_credibility']),
                factCheckResult: result,
              );
              break;
          }
          print('✅ 실시간 서버 저장 완료: $type');
        } catch (e) {
          print('⚠️ 실시간 서버 저장 실패: $e (로컬 저장은 완료됨)');
        }
      }
    } catch (e) {
      print('❌ 분석 결과 저장 오류: $e');
    }
  }
  
  // 신뢰도 점수 변환 헬퍼
  static double _parseCredibilityScore(String? credibility) {
    switch (credibility?.toLowerCase()) {
      case '높음':
      case 'high':
        return 0.8;
      case '보통':
      case 'medium':
        return 0.5;
      case '낮음':
      case 'low':
        return 0.2;
      default:
        return 0.0;
    }
  }
  
  // 동기화 상태 확인
  static Future<Map<String, dynamic>> getSyncStatus() async {
    final userId = await getCurrentUserId();
    final syncEnabled = await isSyncEnabled();
    final lastSync = await getLastSyncTime();
    final isOnline = userId != null && !userId.startsWith('temp_');
    
    return {
      'user_id': userId,
      'sync_enabled': syncEnabled,
      'is_online': isOnline,
      'last_sync': lastSync?.toIso8601String(),
      'status': isOnline ? (syncEnabled ? 'online' : 'offline_by_choice') : 'offline',
    };
  }
  
  // 데이터 백업 생성
  static Future<Map<String, dynamic>> createBackup() async {
    try {
      final mealHistory = await DataStorageService.getMealAnalysisHistory();
      final supplementHistory = await DataStorageService.getSupplementAnalysisHistory();
      final checkupHistory = await DataStorageService.getCheckupAnalysisHistory();
      final factCheckHistory = await DataStorageService.getFactCheckHistory();
      final uploadedFiles = await DataStorageService.getUploadedFiles();
      
      final backup = {
        'version': '1.0',
        'created_at': DateTime.now().toIso8601String(),
        'user_id': await getCurrentUserId(),
        'data': {
          'meals': mealHistory,
          'supplements': supplementHistory,
          'checkups': checkupHistory,
          'fact_checks': factCheckHistory,
          'uploaded_files': uploadedFiles,
        }
      };
      
      print('✅ 백업 생성 완료');
      return backup;
    } catch (e) {
      print('❌ 백업 생성 오류: $e');
      throw Exception('백업 생성 실패: $e');
    }
  }
  
  // 데이터 복원
  static Future<void> restoreFromBackup(Map<String, dynamic> backup) async {
    try {
      final data = backup['data'] as Map<String, dynamic>;
      
      // 기존 데이터 삭제
      await DataStorageService.clearAllData();
      
      // 백업 데이터 복원
      final prefs = await SharedPreferences.getInstance();
      
      if (data['meals'] != null) {
        await prefs.setString('meal_analysis_results', json.encode(data['meals']));
      }
      
      if (data['supplements'] != null) {
        await prefs.setString('supplement_analysis_results', json.encode(data['supplements']));
      }
      
      if (data['checkups'] != null) {
        await prefs.setString('checkup_analysis_results', json.encode(data['checkups']));
      }
      
      if (data['fact_checks'] != null) {
        await prefs.setString('fact_check_results', json.encode(data['fact_checks']));
      }
      
      if (data['uploaded_files'] != null) {
        await prefs.setString('uploaded_files', json.encode(data['uploaded_files']));
      }
      
      // 사용자 ID 복원
      if (backup['user_id'] != null) {
        await setCurrentUserId(backup['user_id']);
      }
      
      print('✅ 백업 복원 완료');
    } catch (e) {
      print('❌ 백업 복원 오류: $e');
      throw Exception('백업 복원 실패: $e');
    }
  }

  // 식단 분석 결과만 서버에 동기화 (무한 루프 방지)
  static Future<void> syncMealAnalysisToServer({
    required Map<String, dynamic> result,
    String? imagePath,
  }) async {
    try {
      final syncEnabled = await isSyncEnabled();
      final userId = await getCurrentUserId();
      
      if (syncEnabled && userId != null && !userId.startsWith('temp_')) {
        // 서버에 식사 기록 저장 (향후 구현 예정)
        // await ApiService.saveMealRecord(...);
        print('🔄 식단 분석 서버 동기화 완료 (사용자: $userId)');
      } else {
        print('🔄 식단 분석 로컬 저장만 완료 (동기화 비활성화)');
      }
    } catch (e) {
      print('⚠️ 식단 분석 서버 동기화 실패: $e');
      // 서버 동기화 실패해도 로컬 저장은 이미 완료되었으므로 에러를 던지지 않음
    }
  }
}