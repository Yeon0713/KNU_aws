import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';
import 'database_sync_service.dart';

class UserService {
  static const String _userProfileKey = 'user_profile';
  static const String _isFirstLaunchKey = 'is_first_launch';
  
  // 사용자 프로필 모델
  static Map<String, dynamic> _defaultProfile = {
    'name': '사용자',
    'age': 30,
    'gender': '남성',
    'height': 170.0,
    'weight': 70.0,
    'health_concerns': <String>[],
    'created_at': DateTime.now().toIso8601String(),
  };
  
  // 현재 사용자 프로필 가져오기
  static Future<Map<String, dynamic>> getCurrentUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_userProfileKey);
      
      if (profileJson != null) {
        final profile = Map<String, dynamic>.from(json.decode(profileJson));
        print('✅ 사용자 프로필 로드: ${profile['name']}');
        return profile;
      } else {
        // 기본 프로필 반환
        print('⚠️ 저장된 프로필 없음, 기본 프로필 사용');
        return Map<String, dynamic>.from(_defaultProfile);
      }
    } catch (e) {
      print('❌ 사용자 프로필 로드 오류: $e');
      return Map<String, dynamic>.from(_defaultProfile);
    }
  }
  
  // 사용자 프로필 저장
  static Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 업데이트 시간 추가
      profile['updated_at'] = DateTime.now().toIso8601String();
      
      await prefs.setString(_userProfileKey, json.encode(profile));
      print('✅ 사용자 프로필 저장: ${profile['name']}');
      
      // 데이터베이스 동기화
      await _syncProfileToDatabase(profile);
    } catch (e) {
      print('❌ 사용자 프로필 저장 오류: $e');
    }
  }
  
  // 데이터베이스와 프로필 동기화
  static Future<void> _syncProfileToDatabase(Map<String, dynamic> profile) async {
    try {
      final userId = await DatabaseSyncService.getCurrentUserId();
      if (userId != null && !userId.startsWith('temp_')) {
        final syncStatus = await DatabaseSyncService.getSyncStatus();
        if (syncStatus['sync_enabled'] == true) {
          await ApiService.updateUser(
            userId: userId,
            name: profile['name'],
            age: profile['age'],
            gender: profile['gender'],
            height: profile['height']?.toDouble(),
            weight: profile['weight']?.toDouble(),
            healthConcerns: List<String>.from(profile['health_concerns'] ?? []),
          );
          print('✅ 사용자 프로필 데이터베이스 동기화 완료');
        }
      }
    } catch (e) {
      print('⚠️ 사용자 프로필 데이터베이스 동기화 실패: $e');
    }
  }
  
  // 사용자 등록/로그인
  static Future<Map<String, dynamic>> registerOrLogin(Map<String, dynamic> profile) async {
    try {
      print('👤 사용자 등록/로그인 시작...');
      
      // 1. 로컬에 프로필 저장
      await saveUserProfile(profile);
      
      // 2. 데이터베이스에 사용자 생성 또는 로그인
      final userId = await DatabaseSyncService.createOrGetUser(
        name: profile['name'] ?? '사용자',
        age: profile['age'] ?? 30,
        gender: profile['gender'] ?? '남성',
        height: (profile['height'] ?? 170.0).toDouble(),
        weight: (profile['weight'] ?? 70.0).toDouble(),
        healthConcerns: List<String>.from(profile['health_concerns'] ?? []),
      );
      
      // 3. 첫 실행 플래그 설정
      await setFirstLaunchCompleted();
      
      // 4. 자동 동기화 시작
      await DatabaseSyncService.autoSync();
      
      return {
        'success': true,
        'user_id': userId,
        'message': '사용자 등록/로그인 완료',
        'is_new_user': !userId.startsWith('temp_'),
      };
    } catch (e) {
      print('❌ 사용자 등록/로그인 오류: $e');
      return {
        'success': false,
        'message': '사용자 등록/로그인 실패: $e',
      };
    }
  }
  
  // 첫 실행 여부 확인
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstLaunchKey) ?? true;
  }
  
  // 첫 실행 완료 설정
  static Future<void> setFirstLaunchCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstLaunchKey, false);
    print('✅ 첫 실행 완료 설정');
  }
  
  // 사용자 로그아웃
  static Future<void> logout() async {
    try {
      print('👤 사용자 로그아웃 시작...');
      
      // 1. 마지막 동기화 수행
      await DatabaseSyncService.fullSync();
      
      // 2. 사용자 ID 삭제
      await DatabaseSyncService.clearCurrentUserId();
      
      // 3. 로컬 프로필은 유지 (재로그인 시 사용)
      
      print('✅ 사용자 로그아웃 완료');
    } catch (e) {
      print('❌ 사용자 로그아웃 오류: $e');
    }
  }
  
  // 계정 삭제 (모든 데이터 삭제)
  static Future<void> deleteAccount() async {
    try {
      print('🗑️ 계정 삭제 시작...');
      
      // 1. 사용자 ID 삭제
      await DatabaseSyncService.clearCurrentUserId();
      
      // 2. 모든 로컬 데이터 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      print('✅ 계정 삭제 완료');
    } catch (e) {
      print('❌ 계정 삭제 오류: $e');
    }
  }
  
  // 프로필 업데이트
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    int? age,
    String? gender,
    double? height,
    double? weight,
    List<String>? healthConcerns,
  }) async {
    try {
      // 현재 프로필 가져오기
      final currentProfile = await getCurrentUserProfile();
      
      // 업데이트할 필드만 변경
      if (name != null) currentProfile['name'] = name;
      if (age != null) currentProfile['age'] = age;
      if (gender != null) currentProfile['gender'] = gender;
      if (height != null) currentProfile['height'] = height;
      if (weight != null) currentProfile['weight'] = weight;
      if (healthConcerns != null) currentProfile['health_concerns'] = healthConcerns;
      
      // 프로필 저장
      await saveUserProfile(currentProfile);
      
      return {
        'success': true,
        'message': '프로필 업데이트 완료',
        'profile': currentProfile,
      };
    } catch (e) {
      print('❌ 프로필 업데이트 오류: $e');
      return {
        'success': false,
        'message': '프로필 업데이트 실패: $e',
      };
    }
  }
  
  // 건강 관심사 추가
  static Future<void> addHealthConcern(String concern) async {
    try {
      final profile = await getCurrentUserProfile();
      final concerns = List<String>.from(profile['health_concerns'] ?? []);
      
      if (!concerns.contains(concern)) {
        concerns.add(concern);
        profile['health_concerns'] = concerns;
        await saveUserProfile(profile);
        print('✅ 건강 관심사 추가: $concern');
      }
    } catch (e) {
      print('❌ 건강 관심사 추가 오류: $e');
    }
  }
  
  // 건강 관심사 제거
  static Future<void> removeHealthConcern(String concern) async {
    try {
      final profile = await getCurrentUserProfile();
      final concerns = List<String>.from(profile['health_concerns'] ?? []);
      
      concerns.remove(concern);
      profile['health_concerns'] = concerns;
      await saveUserProfile(profile);
      print('✅ 건강 관심사 제거: $concern');
    } catch (e) {
      print('❌ 건강 관심사 제거 오류: $e');
    }
  }
  
  // 사용자 상태 확인
  static Future<Map<String, dynamic>> getUserStatus() async {
    try {
      final profile = await getCurrentUserProfile();
      final syncStatus = await DatabaseSyncService.getSyncStatus();
      final isFirstLaunch = await UserService.isFirstLaunch();
      
      return {
        'profile': profile,
        'sync_status': syncStatus,
        'is_first_launch': isFirstLaunch,
        'is_logged_in': syncStatus['user_id'] != null,
        'is_online': syncStatus['is_online'],
      };
    } catch (e) {
      print('❌ 사용자 상태 확인 오류: $e');
      return {
        'profile': _defaultProfile,
        'sync_status': {'status': 'error'},
        'is_first_launch': true,
        'is_logged_in': false,
        'is_online': false,
      };
    }
  }
  
  // BMI 계산
  static double calculateBMI(double height, double weight) {
    if (height <= 0 || weight <= 0) return 0.0;
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }
  
  // BMI 상태 텍스트
  static String getBMIStatus(double bmi) {
    if (bmi < 18.5) return '저체중';
    if (bmi < 23.0) return '정상';
    if (bmi < 25.0) return '과체중';
    if (bmi < 30.0) return '비만';
    return '고도비만';
  }
  
  // 권장 칼로리 계산 (Harris-Benedict 공식)
  static int calculateRecommendedCalories(String gender, int age, double height, double weight) {
    double bmr;
    
    if (gender == '남성') {
      bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }
    
    // 활동 계수 적용 (보통 활동량 1.55)
    return (bmr * 1.55).round();
  }
  
  // 사용자 데이터 백업
  static Future<Map<String, dynamic>> createUserBackup() async {
    try {
      final profile = await getCurrentUserProfile();
      final syncStatus = await DatabaseSyncService.getSyncStatus();
      final dataBackup = await DatabaseSyncService.createBackup();
      
      return {
        'user_profile': profile,
        'sync_status': syncStatus,
        'app_data': dataBackup,
        'backup_created_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ 사용자 백업 생성 오류: $e');
      throw Exception('사용자 백업 생성 실패: $e');
    }
  }
  
  // 사용자 데이터 복원
  static Future<void> restoreUserBackup(Map<String, dynamic> backup) async {
    try {
      // 프로필 복원
      if (backup['user_profile'] != null) {
        await saveUserProfile(backup['user_profile']);
      }
      
      // 앱 데이터 복원
      if (backup['app_data'] != null) {
        await DatabaseSyncService.restoreFromBackup(backup['app_data']);
      }
      
      print('✅ 사용자 백업 복원 완료');
    } catch (e) {
      print('❌ 사용자 백업 복원 오류: $e');
      throw Exception('사용자 백업 복원 실패: $e');
    }
  }
  
  // 개인정보 처리 동의 상태 관리
  static Future<bool> getPrivacyConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('privacy_consent') ?? false;
  }
  
  static Future<void> setPrivacyConsent(bool consent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('privacy_consent', consent);
    
    // 동의하지 않으면 동기화 비활성화
    if (!consent) {
      await DatabaseSyncService.setSyncEnabled(false);
    }
  }
  
  // 데이터 사용 통계
  static Future<Map<String, dynamic>> getDataUsageStats() async {
    try {
      final userId = await DatabaseSyncService.getCurrentUserId();
      if (userId != null && !userId.startsWith('temp_')) {
        final stats = await ApiService.getUserStatistics(userId);
        if (stats['success'] == true) {
          return stats['statistics'];
        }
      }
      
      // 로컬 통계 반환
      return {
        'meals': 0,
        'supplement_analyses': 0,
        'health_checkups': 0,
        'fact_checks': 0,
        'medication_records': 0,
      };
    } catch (e) {
      print('❌ 데이터 사용 통계 조회 오류: $e');
      return {};
    }
  }
}