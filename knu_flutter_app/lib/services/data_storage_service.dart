import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'database_sync_service.dart';

class DataStorageService {
  static const String _supplementAnalysisKey = 'supplement_analysis_results';
  static const String _mealAnalysisKey = 'meal_analysis_results';
  static const String _checkupAnalysisKey = 'checkup_analysis_results';
  static const String _factCheckResultsKey = 'fact_check_results';
  static const String _uploadedFilesKey = 'uploaded_files';

  // 영양제 분석 결과 저장 (데이터베이스 동기화 포함)
  static Future<void> saveSupplementAnalysis(Map<String, dynamic> result) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().toIso8601String();
    
    // 기존 결과들 가져오기
    final existingResults = await getSupplementAnalysisHistory();
    
    // 새 결과 추가 (최신 순으로)
    final newResult = {
      'timestamp': timestamp,
      'data': result,
    };
    
    existingResults.insert(0, newResult);
    
    // 최대 10개까지만 저장
    if (existingResults.length > 10) {
      existingResults.removeRange(10, existingResults.length);
    }
    
    await prefs.setString(_supplementAnalysisKey, json.encode(existingResults));
    
    // 데이터베이스 실시간 동기화
    await DatabaseSyncService.saveAnalysisResult(
      type: 'supplement',
      result: result,
    );
  }

  // 식단 분석 결과 저장 (데이터베이스 동기화 포함)
  static Future<void> saveMealAnalysis(Map<String, dynamic> result, String? imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().toIso8601String();
    
    final existingResults = await getMealAnalysisHistory();
    
    final newResult = {
      'timestamp': timestamp,
      'data': result,
      'imagePath': imagePath,
    };
    
    existingResults.insert(0, newResult);
    
    if (existingResults.length > 20) {
      existingResults.removeRange(20, existingResults.length);
    }
    
    await prefs.setString(_mealAnalysisKey, json.encode(existingResults));
    
    // 데이터베이스 실시간 동기화 (무한 루프 방지를 위해 별도 메서드 사용)
    await DatabaseSyncService.syncMealAnalysisToServer(
      result: result,
      imagePath: imagePath,
    );
  }

  // 건강검진 분석 결과 저장 (데이터베이스 동기화 포함)
  static Future<void> saveCheckupAnalysis(Map<String, dynamic> result, String? imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().toIso8601String();
    
    final existingResults = await getCheckupAnalysisHistory();
    
    final newResult = {
      'timestamp': timestamp,
      'data': result,
      'imagePath': imagePath,
    };
    
    existingResults.insert(0, newResult);
    
    if (existingResults.length > 10) {
      existingResults.removeRange(10, existingResults.length);
    }
    
    await prefs.setString(_checkupAnalysisKey, json.encode(existingResults));
    
    // 데이터베이스 실시간 동기화
    await DatabaseSyncService.saveAnalysisResult(
      type: 'checkup',
      result: result,
      imagePath: imagePath,
    );
  }

  // 팩트체킹 결과 저장 (데이터베이스 동기화 포함)
  static Future<void> saveFactCheckResult(Map<String, dynamic> result, String query) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().toIso8601String();
    
    final existingResults = await getFactCheckHistory();
    
    final newResult = {
      'timestamp': timestamp,
      'query': query,
      'data': result,
    };
    
    existingResults.insert(0, newResult);
    
    if (existingResults.length > 15) {
      existingResults.removeRange(15, existingResults.length);
    }
    
    await prefs.setString(_factCheckResultsKey, json.encode(existingResults));
    
    // 데이터베이스 실시간 동기화
    await DatabaseSyncService.saveAnalysisResult(
      type: 'factcheck',
      result: result,
      query: query,
    );
  }

  // 업로드된 파일 목록 저장
  static Future<void> saveUploadedFile(String fileName, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().toIso8601String();
    
    final existingFiles = await getUploadedFiles();
    
    final newFile = {
      'fileName': fileName,
      'type': type,
      'timestamp': timestamp,
    };
    
    existingFiles.insert(0, newFile);
    
    if (existingFiles.length > 50) {
      existingFiles.removeRange(50, existingFiles.length);
    }
    
    await prefs.setString(_uploadedFilesKey, json.encode(existingFiles));
  }

  // 영양제 분석 기록 가져오기
  static Future<List<Map<String, dynamic>>> getSupplementAnalysisHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_supplementAnalysisKey);
    
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('영양제 분석 기록 로드 오류: $e');
      return [];
    }
  }

  // 식단 분석 기록 가져오기
  static Future<List<Map<String, dynamic>>> getMealAnalysisHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_mealAnalysisKey);
    
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('식단 분석 기록 로드 오류: $e');
      return [];
    }
  }

  // 건강검진 분석 기록 가져오기
  static Future<List<Map<String, dynamic>>> getCheckupAnalysisHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_checkupAnalysisKey);
    
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('건강검진 분석 기록 로드 오류: $e');
      return [];
    }
  }

  // 팩트체킹 기록 가져오기
  static Future<List<Map<String, dynamic>>> getFactCheckHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_factCheckResultsKey);
    
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('팩트체킹 기록 로드 오류: $e');
      return [];
    }
  }

  // 업로드된 파일 목록 가져오기
  static Future<List<Map<String, dynamic>>> getUploadedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_uploadedFilesKey);
    
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('업로드 파일 목록 로드 오류: $e');
      return [];
    }
  }

  // 최신 영양제 분석 결과 가져오기
  static Future<Map<String, dynamic>?> getLatestSupplementAnalysis() async {
    final history = await getSupplementAnalysisHistory();
    return history.isNotEmpty ? history.first['data'] : null;
  }

  // 최신 식단 분석 결과 가져오기
  static Future<Map<String, dynamic>?> getLatestMealAnalysis() async {
    final history = await getMealAnalysisHistory();
    return history.isNotEmpty ? history.first['data'] : null;
  }

  // 최신 건강검진 분석 결과 가져오기
  static Future<Map<String, dynamic>?> getLatestCheckupAnalysis() async {
    final history = await getCheckupAnalysisHistory();
    return history.isNotEmpty ? history.first['data'] : null;
  }

  // 모든 데이터 삭제 (초기화)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_supplementAnalysisKey);
    await prefs.remove(_mealAnalysisKey);
    await prefs.remove(_checkupAnalysisKey);
    await prefs.remove(_factCheckResultsKey);
    await prefs.remove(_uploadedFilesKey);
  }

  // 특정 타입 데이터만 삭제
  static Future<void> clearDataByType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    switch (type) {
      case 'supplement':
        await prefs.remove(_supplementAnalysisKey);
        break;
      case 'meal':
        await prefs.remove(_mealAnalysisKey);
        break;
      case 'checkup':
        await prefs.remove(_checkupAnalysisKey);
        break;
      case 'factcheck':
        await prefs.remove(_factCheckResultsKey);
        break;
      case 'files':
        await prefs.remove(_uploadedFilesKey);
        break;
    }
  }

  // 데이터 통계 가져오기 (데이터베이스 연동)
  static Future<Map<String, int>> getDataStatistics() async {
    final supplementCount = (await getSupplementAnalysisHistory()).length;
    final mealCount = (await getMealAnalysisHistory()).length;
    final checkupCount = (await getCheckupAnalysisHistory()).length;
    final factCheckCount = (await getFactCheckHistory()).length;
    final fileCount = (await getUploadedFiles()).length;

    return {
      'supplements': supplementCount,
      'meals': mealCount,
      'checkups': checkupCount,
      'factChecks': factCheckCount,
      'files': fileCount,
    };
  }

  // 서버와 데이터 동기화
  static Future<Map<String, dynamic>> syncWithServer() async {
    try {
      print('🔄 데이터 서버 동기화 시작...');
      
      final syncResult = await DatabaseSyncService.fullSync();
      
      if (syncResult['success'] == true) {
        print('✅ 데이터 서버 동기화 완료');
        return {
          'success': true,
          'message': '데이터 동기화 완료',
          'sync_result': syncResult,
        };
      } else {
        throw Exception(syncResult['message']);
      }
    } catch (e) {
      print('❌ 데이터 서버 동기화 실패: $e');
      return {
        'success': false,
        'message': '데이터 동기화 실패: $e',
      };
    }
  }

  // 동기화 상태 확인
  static Future<Map<String, dynamic>> getSyncStatus() async {
    return await DatabaseSyncService.getSyncStatus();
  }

  // 동기화 설정 변경
  static Future<void> setSyncEnabled(bool enabled) async {
    await DatabaseSyncService.setSyncEnabled(enabled);
  }

  // 백업 생성
  static Future<Map<String, dynamic>> createBackup() async {
    return await DatabaseSyncService.createBackup();
  }

  // 백업 복원
  static Future<void> restoreFromBackup(Map<String, dynamic> backup) async {
    await DatabaseSyncService.restoreFromBackup(backup);
  }
}