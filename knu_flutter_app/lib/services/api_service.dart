import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://fdd9fa5caa0eac14bb336cfafcb5f6e2-20286164.ap-northeast-2.elb.amazonaws.com';
  
  // 사용자 정보 모델
  static Map<String, dynamic> _createUserInfo(String name, int age, String gender, int height, int weight) {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
    };
  }

  // 건강검진 분석 API 호출
  static Future<Map<String, dynamic>> analyzeCheckup({
    required String name,
    required int age,
    required String gender,
    required int height,
    required int weight,
    required String checkupText,
  }) async {
    try {
      print('🏥 건강검진 분석 API 호출 시작: $baseUrl/api/analyze-checkup');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/analyze-checkup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_info': _createUserInfo(name, age, gender, height, weight),
          'checkup_text': checkupText,
        }),
      ).timeout(const Duration(seconds: 60)); // 60초 타임아웃 추가

      print('📡 건강검진 API 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ 건강검진 분석 성공');
        return data['data'];
      } else {
        print('❌ 건강검진 API 응답 오류: ${response.statusCode} - ${response.body}');
        throw Exception('건강검진 분석 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 건강검진 API 호출 예외: $e');
      throw Exception('건강검진 API 호출 오류: $e');
    }
  }

  // 식단 분석 API 호출
  static Future<Map<String, dynamic>> analyzeMeal({
    required String name,
    required int age,
    required String gender,
    required int height,
    required int weight,
    required String imageBase64,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/analyze-meal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_info': _createUserInfo(name, age, gender, height, weight),
          'image_base64': imageBase64,
        }),
      ).timeout(const Duration(seconds: 60)); // 60초 타임아웃 추가

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('식단 분석 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API 호출 오류: $e');
    }
  }

  // 빠른 영양제 추천 API 호출 (기본 추천)
  static Future<Map<String, dynamic>> recommendSupplementsFast({
    required String name,
    required int age,
    required String gender,
    required int height,
    required int weight,
    required Map<String, dynamic> checkupResult,
    required Map<String, dynamic> mealResult,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/recommend-supplements-fast'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_info': _createUserInfo(name, age, gender, height, weight),
          'checkup_result': checkupResult,
          'meal_result': mealResult,
        }),
      ).timeout(const Duration(seconds: 10)); // 10초 타임아웃

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('빠른 영양제 추천 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('빠른 API 호출 오류: $e');
    }
  }

  // 영양제 추천 API 호출
  static Future<Map<String, dynamic>> recommendSupplements({
    required String name,
    required int age,
    required String gender,
    required int height,
    required int weight,
    required Map<String, dynamic> checkupResult,
    required Map<String, dynamic> mealResult,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/recommend-supplements'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_info': _createUserInfo(name, age, gender, height, weight),
          'checkup_result': checkupResult,
          'meal_result': mealResult,
        }),
      ).timeout(const Duration(seconds: 30)); // 영양제 추천은 30초 타임아웃으로 단축

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('영양제 추천 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API 호출 오류: $e');
    }
  }

  // 서버 상태 확인
  static Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 건강검진 이미지 분석 API 호출
  static Future<Map<String, dynamic>> analyzeCheckupImage({
    required String name,
    required int age,
    required String gender,
    required int height,
    required int weight,
    required String imageBase64,
  }) async {
    try {
      print('🏥 건강검진 이미지 분석 API 호출 시작: $baseUrl/api/analyze-checkup-image');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/analyze-checkup-image'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_info': _createUserInfo(name, age, gender, height, weight),
          'image_base64': imageBase64,
        }),
      );

      print('📡 건강검진 이미지 API 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ 건강검진 이미지 분석 성공');
        return data['data'];
      } else {
        print('❌ 건강검진 이미지 API 응답 오류: ${response.statusCode} - ${response.body}');
        throw Exception('건강검진 이미지 분석 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 건강검진 이미지 API 호출 예외: $e');
      throw Exception('건강검진 이미지 API 호출 오류: $e');
    }
  }
  static String encodeImageToBase64(File imageFile) {
    final bytes = imageFile.readAsBytesSync();
    return base64Encode(bytes);
  }

  // 유튜브 팩트체킹 API 호출
  static Future<Map<String, dynamic>> factCheckYoutube({
    required String name,
    required int age,
    required String gender,
    required int height,
    required int weight,
    required String youtubeUrl,
  }) async {
    try {
      print('🌐 팩트체크 API 호출 시작: $baseUrl/api/fact-check-youtube');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/fact-check-youtube'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_info': _createUserInfo(name, age, gender, height, weight),
          'youtube_url': youtubeUrl,
        }),
      ); // 타임아웃 제거 - 유튜브 분석은 시간이 오래 걸릴 수 있음

      print('📡 API 응답 상태: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ 팩트체크 API 호출 성공');
        return data['data'];
      } else {
        print('❌ API 응답 오류: ${response.statusCode} - ${response.body}');
        throw Exception('팩트체킹 실패: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ 팩트체크 API 호출 예외: $e');
      
      if (e.toString().contains('SocketException')) {
        throw Exception('네트워크 연결을 확인해주세요. (서버: $baseUrl)');
      } else {
        throw Exception('팩트체킹 API 호출 오류: $e');
      }
    }
  }

  // ==================== 데이터베이스 연동 API ====================

  // 사용자 생성
  static Future<Map<String, dynamic>> createUser({
    required String name,
    required int age,
    required String gender,
    required double height,
    required double weight,
    List<String> healthConcerns = const [],
  }) async {
    try {
      print('👤 사용자 생성 API 호출: $baseUrl/api/users');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'age': age,
          'gender': gender,
          'height': height,
          'weight': weight,
          'health_concerns': healthConcerns,
        }),
      );

      print('📡 사용자 생성 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ 사용자 생성 성공: ${data['user_id']}');
        return data;
      } else {
        print('❌ 사용자 생성 실패: ${response.statusCode} - ${response.body}');
        throw Exception('사용자 생성 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 사용자 생성 API 호출 예외: $e');
      throw Exception('사용자 생성 API 호출 오류: $e');
    }
  }

  // 사용자 정보 조회
  static Future<Map<String, dynamic>> getUser(String userId) async {
    try {
      print('👤 사용자 조회 API 호출: $baseUrl/api/users/$userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 사용자 조회 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ 사용자 조회 성공');
        return data;
      } else {
        print('❌ 사용자 조회 실패: ${response.statusCode} - ${response.body}');
        throw Exception('사용자 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 사용자 조회 API 호출 예외: $e');
      throw Exception('사용자 조회 API 호출 오류: $e');
    }
  }

  // 사용자 정보 업데이트
  static Future<Map<String, dynamic>> updateUser({
    required String userId,
    String? name,
    int? age,
    String? gender,
    double? height,
    double? weight,
    List<String>? healthConcerns,
  }) async {
    try {
      print('👤 사용자 업데이트 API 호출: $baseUrl/api/users/$userId');
      
      final Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (age != null) updateData['age'] = age;
      if (gender != null) updateData['gender'] = gender;
      if (height != null) updateData['height'] = height;
      if (weight != null) updateData['weight'] = weight;
      if (healthConcerns != null) updateData['health_concerns'] = healthConcerns;
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );

      print('📡 사용자 업데이트 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ 사용자 업데이트 성공');
        return data;
      } else {
        print('❌ 사용자 업데이트 실패: ${response.statusCode} - ${response.body}');
        throw Exception('사용자 업데이트 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 사용자 업데이트 API 호출 예외: $e');
      throw Exception('사용자 업데이트 API 호출 오류: $e');
    }
  }

  // 식사 기록 저장
  static Future<Map<String, dynamic>> saveMealRecord({
    required String userId,
    required String date,
    required String mealType,
    required List<String> foods,
    Map<String, dynamic> nutrients = const {},
    double calories = 0,
    String? imagePath,
    Map<String, dynamic> aiAnalysis = const {},
  }) async {
    try {
      print('🍽️ 식사 기록 저장 API 호출: $baseUrl/api/users/$userId/meals');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/$userId/meals'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'date': date,
          'meal_type': mealType,
          'foods': foods,
          'nutrients': nutrients,
          'calories': calories,
          'image_path': imagePath,
          'ai_analysis': aiAnalysis,
        }),
      );

      print('📡 식사 기록 저장 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ 식사 기록 저장 성공');
        return data;
      } else {
        print('❌ 식사 기록 저장 실패: ${response.statusCode} - ${response.body}');
        throw Exception('식사 기록 저장 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 식사 기록 저장 API 호출 예외: $e');
      throw Exception('식사 기록 저장 API 호출 오류: $e');
    }
  }

  // 식사 기록 조회
  static Future<Map<String, dynamic>> getMealRecords({
    required String userId,
    String? date,
    String? startDate,
    String? endDate,
  }) async {
    try {
      String url = '$baseUrl/api/users/$userId/meals';
      List<String> queryParams = [];
      
      if (date != null) queryParams.add('date=$date');
      if (startDate != null) queryParams.add('start_date=$startDate');
      if (endDate != null) queryParams.add('end_date=$endDate');
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }
      
      print('🍽️ 식사 기록 조회 API 호출: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 식사 기록 조회 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ 식사 기록 조회 성공: ${data['total_count']}개');
        return data;
      } else {
        print('❌ 식사 기록 조회 실패: ${response.statusCode} - ${response.body}');
        throw Exception('식사 기록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 식사 기록 조회 API 호출 예외: $e');
      throw Exception('식사 기록 조회 API 호출 오류: $e');
    }
  }

  // 영양제 분석 결과 저장
  static Future<Map<String, dynamic>> saveSupplementAnalysis({
    required String userId,
    required Map<String, dynamic> analysisResult,
    List<Map<String, dynamic>> recommendedSupplements = const [],
    List<String> deficientNutrients = const [],
  }) async {
    try {
      print('💊 영양제 분석 저장 API 호출: $baseUrl/api/users/$userId/supplement-analysis');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/$userId/supplement-analysis'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'analysis_result': analysisResult,
          'recommended_supplements': recommendedSupplements,
          'deficient_nutrients': deficientNutrients,
        }),
      );

      print('📡 영양제 분석 저장 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ 영양제 분석 저장 성공');
        return data;
      } else {
        print('❌ 영양제 분석 저장 실패: ${response.statusCode} - ${response.body}');
        throw Exception('영양제 분석 저장 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 영양제 분석 저장 API 호출 예외: $e');
      throw Exception('영양제 분석 저장 API 호출 오류: $e');
    }
  }

  // 최신 영양제 분석 결과 조회
  static Future<Map<String, dynamic>> getLatestSupplementAnalysis(String userId) async {
    try {
      print('💊 최신 영양제 분석 조회 API 호출: $baseUrl/api/users/$userId/supplement-analysis/latest');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/supplement-analysis/latest'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 최신 영양제 분석 조회 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ 최신 영양제 분석 조회 성공');
        return data;
      } else {
        print('❌ 최신 영양제 분석 조회 실패: ${response.statusCode} - ${response.body}');
        throw Exception('최신 영양제 분석 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 최신 영양제 분석 조회 API 호출 예외: $e');
      throw Exception('최신 영양제 분석 조회 API 호출 오류: $e');
    }
  }

  // 건강검진 결과 저장
  static Future<Map<String, dynamic>> saveHealthCheckup({
    required String userId,
    required String checkupDate,
    required Map<String, dynamic> checkupData,
    Map<String, dynamic> aiAnalysis = const {},
    String status = "",
    String? imagePath,
  }) async {
    try {
      print('🏥 건강검진 저장 API 호출: $baseUrl/api/users/$userId/health-checkups');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/$userId/health-checkups'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'checkup_date': checkupDate,
          'checkup_data': checkupData,
          'ai_analysis': aiAnalysis,
          'status': status,
          'image_path': imagePath,
        }),
      );

      print('📡 건강검진 저장 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ 건강검진 저장 성공');
        return data;
      } else {
        print('❌ 건강검진 저장 실패: ${response.statusCode} - ${response.body}');
        throw Exception('건강검진 저장 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 건강검진 저장 API 호출 예외: $e');
      throw Exception('건강검진 저장 API 호출 오류: $e');
    }
  }

  // 최신 건강검진 결과 조회
  static Future<Map<String, dynamic>> getLatestHealthCheckup(String userId) async {
    try {
      print('🏥 최신 건강검진 조회 API 호출: $baseUrl/api/users/$userId/health-checkups/latest');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/health-checkups/latest'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 최신 건강검진 조회 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ 최신 건강검진 조회 성공');
        return data;
      } else {
        print('❌ 최신 건강검진 조회 실패: ${response.statusCode} - ${response.body}');
        throw Exception('최신 건강검진 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 최신 건강검진 조회 API 호출 예외: $e');
      throw Exception('최신 건강검진 조회 API 호출 오류: $e');
    }
  }

  // 팩트체크 결과 저장
  static Future<Map<String, dynamic>> saveFactCheck({
    required String userId,
    required String query,
    String sourceType = "text",
    double credibilityScore = 0,
    Map<String, dynamic> factCheckResult = const {},
  }) async {
    try {
      print('🔍 팩트체크 저장 API 호출: $baseUrl/api/users/$userId/fact-checks');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/$userId/fact-checks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'source_type': sourceType,
          'credibility_score': credibilityScore,
          'fact_check_result': factCheckResult,
        }),
      );

      print('📡 팩트체크 저장 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ 팩트체크 저장 성공');
        return data;
      } else {
        print('❌ 팩트체크 저장 실패: ${response.statusCode} - ${response.body}');
        throw Exception('팩트체크 저장 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 팩트체크 저장 API 호출 예외: $e');
      throw Exception('팩트체크 저장 API 호출 오류: $e');
    }
  }

  // 팩트체크 기록 조회
  static Future<Map<String, dynamic>> getFactCheckHistory(String userId, {int limit = 15}) async {
    try {
      print('🔍 팩트체크 기록 조회 API 호출: $baseUrl/api/users/$userId/fact-checks?limit=$limit');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/fact-checks?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 팩트체크 기록 조회 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ 팩트체크 기록 조회 성공: ${data['total_count']}개');
        return data;
      } else {
        print('❌ 팩트체크 기록 조회 실패: ${response.statusCode} - ${response.body}');
        throw Exception('팩트체크 기록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 팩트체크 기록 조회 API 호출 예외: $e');
      throw Exception('팩트체크 기록 조회 API 호출 오류: $e');
    }
  }

  // 복용 기록 추가
  static Future<Map<String, dynamic>> addMedicationRecord({
    required String userId,
    required String date,
    required String medicationName,
    required String dosage,
    bool taken = false,
  }) async {
    try {
      print('💊 복용 기록 추가 API 호출: $baseUrl/api/users/$userId/medications');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/$userId/medications'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'date': date,
          'medication_name': medicationName,
          'dosage': dosage,
          'taken': taken,
        }),
      );

      print('📡 복용 기록 추가 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ 복용 기록 추가 성공');
        return data;
      } else {
        print('❌ 복용 기록 추가 실패: ${response.statusCode} - ${response.body}');
        throw Exception('복용 기록 추가 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 복용 기록 추가 API 호출 예외: $e');
      throw Exception('복용 기록 추가 API 호출 오류: $e');
    }
  }

  // 복용 상태 업데이트
  static Future<Map<String, dynamic>> updateMedicationTaken({
    required String userId,
    required String date,
    required String medicationName,
    required bool taken,
  }) async {
    try {
      print('💊 복용 상태 업데이트 API 호출: $baseUrl/api/users/$userId/medications/$date/$medicationName');
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/users/$userId/medications/$date/$medicationName?taken=$taken'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 복용 상태 업데이트 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ 복용 상태 업데이트 성공');
        return data;
      } else {
        print('❌ 복용 상태 업데이트 실패: ${response.statusCode} - ${response.body}');
        throw Exception('복용 상태 업데이트 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 복용 상태 업데이트 API 호출 예외: $e');
      throw Exception('복용 상태 업데이트 API 호출 오류: $e');
    }
  }

  // 복용 기록 조회
  static Future<Map<String, dynamic>> getMedicationRecords({
    required String userId,
    required String date,
  }) async {
    try {
      print('💊 복용 기록 조회 API 호출: $baseUrl/api/users/$userId/medications?date=$date');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/medications?date=$date'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 복용 기록 조회 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ 복용 기록 조회 성공: ${data['total_count']}개');
        return data;
      } else {
        print('❌ 복용 기록 조회 실패: ${response.statusCode} - ${response.body}');
        throw Exception('복용 기록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 복용 기록 조회 API 호출 예외: $e');
      throw Exception('복용 기록 조회 API 호출 오류: $e');
    }
  }

  // 사용자 통계 조회
  static Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    try {
      print('📊 사용자 통계 조회 API 호출: $baseUrl/api/users/$userId/statistics');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/statistics'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 사용자 통계 조회 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ 사용자 통계 조회 성공');
        return data;
      } else {
        print('❌ 사용자 통계 조회 실패: ${response.statusCode} - ${response.body}');
        throw Exception('사용자 통계 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 사용자 통계 조회 API 호출 예외: $e');
      throw Exception('사용자 통계 조회 API 호출 오류: $e');
    }
  }

  // 데이터 동기화
  static Future<Map<String, dynamic>> syncUserData({
    required String userId,
    List<Map<String, dynamic>> meals = const [],
    List<Map<String, dynamic>> supplementAnalyses = const [],
    List<Map<String, dynamic>> healthCheckups = const [],
    List<Map<String, dynamic>> factChecks = const [],
    List<Map<String, dynamic>> medicationRecords = const [],
  }) async {
    try {
      print('🔄 데이터 동기화 API 호출: $baseUrl/api/users/$userId/sync');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/$userId/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'meals': meals,
          'supplement_analyses': supplementAnalyses,
          'health_checkups': healthCheckups,
          'fact_checks': factChecks,
          'medication_records': medicationRecords,
        }),
      );

      print('📡 데이터 동기화 응답 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ 데이터 동기화 성공: ${data['sync_result']}');
        return data;
      } else {
        print('❌ 데이터 동기화 실패: ${response.statusCode} - ${response.body}');
        throw Exception('데이터 동기화 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 데이터 동기화 API 호출 예외: $e');
      throw Exception('데이터 동기화 API 호출 오류: $e');
    }
  }
}