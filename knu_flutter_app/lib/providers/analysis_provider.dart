import 'package:flutter/material.dart';
import '../services/data_storage_service.dart';

class AnalysisProvider with ChangeNotifier {
  // 현재 분석 결과들
  Map<String, dynamic>? _currentSupplementAnalysis;
  Map<String, dynamic>? _currentMealAnalysis;
  Map<String, dynamic>? _currentCheckupAnalysis;
  Map<String, dynamic>? _currentFactCheckResult;

  // 분석 기록들
  List<Map<String, dynamic>> _supplementHistory = [];
  List<Map<String, dynamic>> _mealHistory = [];
  List<Map<String, dynamic>> _checkupHistory = [];
  List<Map<String, dynamic>> _factCheckHistory = [];
  List<Map<String, dynamic>> _uploadedFiles = [];

  // 로딩 상태
  bool _isLoadingSupplements = false;
  bool _isLoadingMeals = false;
  bool _isLoadingCheckup = false;
  bool _isLoadingFactCheck = false;

  // Getters
  Map<String, dynamic>? get currentSupplementAnalysis => _currentSupplementAnalysis;
  Map<String, dynamic>? get currentMealAnalysis => _currentMealAnalysis;
  Map<String, dynamic>? get currentCheckupAnalysis => _currentCheckupAnalysis;
  Map<String, dynamic>? get currentFactCheckResult => _currentFactCheckResult;

  List<Map<String, dynamic>> get supplementHistory => _supplementHistory;
  List<Map<String, dynamic>> get mealHistory => _mealHistory;
  List<Map<String, dynamic>> get checkupHistory => _checkupHistory;
  List<Map<String, dynamic>> get factCheckHistory => _factCheckHistory;
  List<Map<String, dynamic>> get uploadedFiles => _uploadedFiles;

  bool get isLoadingSupplements => _isLoadingSupplements;
  bool get isLoadingMeals => _isLoadingMeals;
  bool get isLoadingCheckup => _isLoadingCheckup;
  bool get isLoadingFactCheck => _isLoadingFactCheck;

  // 초기화 - 저장된 데이터 로드
  Future<void> initialize() async {
    await loadAllData();
  }

  // 모든 저장된 데이터 로드
  Future<void> loadAllData() async {
    try {
      _supplementHistory = await DataStorageService.getSupplementAnalysisHistory();
      _mealHistory = await DataStorageService.getMealAnalysisHistory();
      _checkupHistory = await DataStorageService.getCheckupAnalysisHistory();
      _factCheckHistory = await DataStorageService.getFactCheckHistory();
      _uploadedFiles = await DataStorageService.getUploadedFiles();

      // 최신 결과들 설정
      _currentSupplementAnalysis = await DataStorageService.getLatestSupplementAnalysis();
      _currentMealAnalysis = await DataStorageService.getLatestMealAnalysis();
      _currentCheckupAnalysis = await DataStorageService.getLatestCheckupAnalysis();

      notifyListeners();
    } catch (e) {
      print('데이터 로드 오류: $e');
    }
  }

  // 영양제 분석 결과 저장
  Future<void> saveSupplementAnalysis(Map<String, dynamic> result) async {
    _isLoadingSupplements = true;
    
    // 먼저 메모리에 저장 (즉시 UI 업데이트)
    _currentSupplementAnalysis = result;
    notifyListeners();

    try {
      // 타임아웃을 설정하여 무한 대기 방지
      await DataStorageService.saveSupplementAnalysis(result).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ 영양제 분석 저장 타임아웃, 메모리에만 저장');
          throw Exception('저장 타임아웃');
        },
      );
      
      // 기록 업데이트를 비동기로 처리 (블로킹하지 않음)
      _refreshSupplementHistory().catchError((e) {
        print('⚠️ 영양제 기록 새로고침 실패: $e');
      });
      
      print('✅ 영양제 분석 결과 저장 완료');
    } catch (e) {
      if (e.toString().contains('저장 타임아웃')) {
        print('⚠️ 분석 결과 저장 실패, 결과만 표시: $e');
      } else {
        print('❌ 영양제 분석 결과 저장 오류: $e');
      }
      // 오류가 발생해도 메모리에는 이미 저장되어 있음
    } finally {
      _isLoadingSupplements = false;
      notifyListeners();
    }
  }

  // 식단 분석 결과 저장
  Future<void> saveMealAnalysis(Map<String, dynamic> result, String? imagePath) async {
    _isLoadingMeals = true;
    notifyListeners();

    try {
      await DataStorageService.saveMealAnalysis(result, imagePath);
      _currentMealAnalysis = result;
      
      // 기록 업데이트
      await _refreshMealHistory();
      
      print('✅ 식단 분석 결과 저장 완료');
    } catch (e) {
      print('❌ 식단 분석 결과 저장 오류: $e');
    } finally {
      _isLoadingMeals = false;
      notifyListeners();
    }
  }

  // 건강검진 분석 결과 저장
  Future<void> saveCheckupAnalysis(Map<String, dynamic> result, String? imagePath) async {
    _isLoadingCheckup = true;
    notifyListeners();

    try {
      await DataStorageService.saveCheckupAnalysis(result, imagePath);
      _currentCheckupAnalysis = result;
      
      // 기록 업데이트
      await _refreshCheckupHistory();
      
      print('✅ 건강검진 분석 결과 저장 완료');
    } catch (e) {
      print('❌ 건강검진 분석 결과 저장 오류: $e');
    } finally {
      _isLoadingCheckup = false;
      notifyListeners();
    }
  }

  // 팩트체킹 결과 저장
  Future<void> saveFactCheckResult(Map<String, dynamic> result, String query) async {
    _isLoadingFactCheck = true;
    notifyListeners();

    try {
      await DataStorageService.saveFactCheckResult(result, query);
      _currentFactCheckResult = result;
      
      // 기록 업데이트
      await _refreshFactCheckHistory();
      
      print('✅ 팩트체킹 결과 저장 완료');
    } catch (e) {
      print('❌ 팩트체킹 결과 저장 오류: $e');
    } finally {
      _isLoadingFactCheck = false;
      notifyListeners();
    }
  }

  // 파일 업로드 기록
  Future<void> saveUploadedFile(String fileName, String type) async {
    try {
      await DataStorageService.saveUploadedFile(fileName, type);
      await _refreshUploadedFiles();
      print('✅ 파일 업로드 기록 저장 완료: $fileName');
    } catch (e) {
      print('❌ 파일 업로드 기록 저장 오류: $e');
    }
  }

  // 개별 기록 새로고침 메서드들
  Future<void> _refreshSupplementHistory() async {
    _supplementHistory = await DataStorageService.getSupplementAnalysisHistory();
  }

  Future<void> _refreshMealHistory() async {
    _mealHistory = await DataStorageService.getMealAnalysisHistory();
  }

  Future<void> _refreshCheckupHistory() async {
    _checkupHistory = await DataStorageService.getCheckupAnalysisHistory();
  }

  Future<void> _refreshFactCheckHistory() async {
    _factCheckHistory = await DataStorageService.getFactCheckHistory();
  }

  Future<void> _refreshUploadedFiles() async {
    _uploadedFiles = await DataStorageService.getUploadedFiles();
  }

  // 특정 분석 결과 가져오기 (인덱스로)
  Map<String, dynamic>? getSupplementAnalysisByIndex(int index) {
    if (index >= 0 && index < _supplementHistory.length) {
      return _supplementHistory[index]['data'];
    }
    return null;
  }

  Map<String, dynamic>? getMealAnalysisByIndex(int index) {
    if (index >= 0 && index < _mealHistory.length) {
      return _mealHistory[index]['data'];
    }
    return null;
  }

  Map<String, dynamic>? getCheckupAnalysisByIndex(int index) {
    if (index >= 0 && index < _checkupHistory.length) {
      return _checkupHistory[index]['data'];
    }
    return null;
  }

  // 데이터 삭제
  Future<void> clearAllData() async {
    await DataStorageService.clearAllData();
    
    _currentSupplementAnalysis = null;
    _currentMealAnalysis = null;
    _currentCheckupAnalysis = null;
    _currentFactCheckResult = null;
    
    _supplementHistory.clear();
    _mealHistory.clear();
    _checkupHistory.clear();
    _factCheckHistory.clear();
    _uploadedFiles.clear();
    
    notifyListeners();
    print('✅ 모든 분석 데이터 삭제 완료');
  }

  Future<void> clearDataByType(String type) async {
    await DataStorageService.clearDataByType(type);
    
    switch (type) {
      case 'supplement':
        _currentSupplementAnalysis = null;
        _supplementHistory.clear();
        break;
      case 'meal':
        _currentMealAnalysis = null;
        _mealHistory.clear();
        break;
      case 'checkup':
        _currentCheckupAnalysis = null;
        _checkupHistory.clear();
        break;
      case 'factcheck':
        _currentFactCheckResult = null;
        _factCheckHistory.clear();
        break;
      case 'files':
        _uploadedFiles.clear();
        break;
    }
    
    notifyListeners();
    print('✅ $type 데이터 삭제 완료');
  }

  // 데이터 통계
  Future<Map<String, int>> getDataStatistics() async {
    return await DataStorageService.getDataStatistics();
  }

  // 분석 결과가 있는지 확인
  bool hasSupplementAnalysis() => _currentSupplementAnalysis != null;
  bool hasMealAnalysis() => _currentMealAnalysis != null;
  bool hasCheckupAnalysis() => _currentCheckupAnalysis != null;
  bool hasFactCheckResult() => _currentFactCheckResult != null;

  // 분석 결과 요약 정보
  String getSupplementSummary() {
    if (_currentSupplementAnalysis == null) return '분석 결과 없음';
    
    final content = _currentSupplementAnalysis!['content'] ?? '';
    return content.length > 50 ? '${content.substring(0, 50)}...' : content;
  }

  String getMealSummary() {
    if (_currentMealAnalysis == null) return '분석 결과 없음';
    
    final foods = _currentMealAnalysis!['detected_foods'] as List<dynamic>? ?? [];
    return foods.isNotEmpty ? foods.join(', ') : '음식 인식 결과 없음';
  }

  String getCheckupSummary() {
    if (_currentCheckupAnalysis == null) return '분석 결과 없음';
    
    final status = _currentCheckupAnalysis!['status'] ?? 'Unknown';
    return '건강 상태: $status';
  }
}