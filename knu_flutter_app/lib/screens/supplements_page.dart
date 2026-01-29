import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/user_data.dart';
import '../services/api_service.dart';
import '../providers/analysis_provider.dart';
import '../providers/meal_data_provider.dart';
import '../widgets/persistent_analysis_widget.dart';
import 'package:intl/intl.dart';

class SupplementsPage extends StatefulWidget {
  final UserData userData;

  const SupplementsPage({super.key, required this.userData});

  @override
  State<SupplementsPage> createState() => _SupplementsPageState();
}

class _SupplementsPageState extends State<SupplementsPage> {
  bool _isAnalyzing = false;
  String _analysisStep = '';
  double _analysisProgress = 0.0;
  Map<String, dynamic>? _aiAnalysisResult;
  
  // 음식별 영양소 함량 데이터베이스 (100g당)
  final Map<String, Map<String, double>> foodNutrientDatabase = {
    // 곡물류
    '밥': {'칼슘': 3, '마그네슘': 12, '칼륨': 35, '비타민 B12': 0},
    '현미밥': {'칼슘': 10, '마그네슘': 43, '칼륨': 118, '비타민 B12': 0},
    '빵': {'칼슘': 50, '마그네슘': 20, '칼륨': 100, '비타민 B12': 0},
    '통밀빵': {'칼슘': 60, '마그네슘': 70, '칼륨': 200, '비타민 B12': 0},
    '오트밀': {'칼슘': 54, '마그네슘': 177, '칼륨': 429, '비타민 B12': 0},
    
    // 단백질류
    '계란': {'칼슘': 50, '마그네슘': 12, '칼륨': 138, '비타민 B12': 1.1, '비타민D': 82},
    '닭가슴살': {'칼슘': 15, '마그네슘': 29, '칼륨': 256, '비타민 B12': 0.3},
    '연어': {'칼슘': 12, '마그네슘': 29, '칼륨': 363, '비타민 B12': 3.2, '비타민D': 526, '오메가3': 2260},
    '불고기': {'칼슘': 10, '마그네슘': 20, '칼륨': 300, '비타민 B12': 2.0},
    
    // 채소류
    '김치': {'칼슘': 45, '마그네슘': 14, '칼륨': 211, '유산균': 100},
    '브로콜리': {'칼슘': 47, '마그네슘': 21, '칼륨': 316, '비타민D': 0},
    '시금치': {'칼슘': 99, '마그네슘': 79, '칼륨': 558},
    '샐러드': {'칼슘': 30, '마그네슘': 15, '칼륨': 200},
    
    // 유제품
    '우유': {'칼슘': 113, '마그네슘': 10, '칼륨': 150, '비타민 B12': 0.4, '비타민D': 40},
    '요거트': {'칼슘': 121, '마그네슘': 12, '칼륨': 155, '비타민 B12': 0.5, '유산균': 1000},
    '치즈': {'칼슘': 721, '마그네슘': 28, '칼륨': 98, '비타민 B12': 1.5},
    
    // 과일류
    '바나나': {'칼슘': 5, '마그네슘': 27, '칼륨': 358},
    '사과': {'칼슘': 6, '마그네슘': 5, '칼륨': 107},
    
    // 견과류
    '견과류': {'칼슘': 70, '마그네슘': 270, '칼륨': 600, '오메가3': 2500},
    '아보카도': {'칼슘': 12, '마그네슘': 29, '칼륨': 485},
    
    // 기타
    '된장찌개': {'칼슘': 40, '마그네슘': 30, '칼륨': 250, '유산균': 50},
    '미역국': {'칼슘': 150, '마그네슘': 50, '칼륨': 300},
    '고구마': {'칼슘': 30, '마그네슘': 25, '칼륨': 337},
  };
  
  // 오늘 날짜의 식단에서 섭취한 영양소 계산
  Map<String, double> _calculateNutrientsFromMeals() {
    final mealProvider = Provider.of<MealDataProvider>(context, listen: false);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayMeals = mealProvider.getMealsForDate(today);
    
    Map<String, double> totalNutrients = {
      '오메가3': 0,
      '비타민D': 0,
      '칼슘': 0,
      '유산균': 0,
      '비타민 B12': 0,
      '마그네슘': 0,
      '코엔자임 Q10': 0,
      '칼륨': 0,
    };
    
    for (var meal in todayMeals) {
      final foods = meal['foods'] as List<dynamic>? ?? [];
      for (var food in foods) {
        final foodStr = food.toString();
        final nutrients = foodNutrientDatabase[foodStr];
        
        if (nutrients != null) {
          nutrients.forEach((nutrient, amount) {
            if (totalNutrients.containsKey(nutrient)) {
              // 1인분을 약 150g으로 가정
              totalNutrients[nutrient] = (totalNutrients[nutrient] ?? 0) + (amount * 1.5);
            }
          });
        }
      }
    }
    
    return totalNutrients;
  }

  // 총 섭취량 계산 (식단 + 영양제)
  Map<String, double> _calculateTotalIntake(String supplementName, String dosageStr) {
    final nutrientsFromMeals = _calculateNutrientsFromMeals();
    final foodIntake = nutrientsFromMeals[supplementName] ?? 0;
    final supplementIntake = _parseDosage(dosageStr);
    final totalIntake = foodIntake + supplementIntake;
    
    return {
      'food': foodIntake,
      'supplement': supplementIntake,
      'total': totalIntake,
    };
  }
  
  // 부족한 영양소 찾기
  List<Map<String, dynamic>> _getDeficientNutrients() {
    final List<Map<String, dynamic>> deficientList = [];
    
    for (var supplement in currentSupplements) {
      final adequacyLevel = _calculateAdequacyLevel(
        supplement['name'], 
        supplement['dosage'], 
        supplement['dailyRecommended']
      );
      
      if (adequacyLevel == '부족') {
        final totalIntake = _calculateTotalIntake(supplement['name'], supplement['dosage']);
        final recommended = _parseRecommendedRange(supplement['dailyRecommended']);
        
        deficientList.add({
          'name': supplement['name'],
          'current': totalIntake['total']!,
          'recommended': recommended['min']!,
          'deficit': recommended['min']! - totalIntake['total']!,
          'unit': _getUnit(supplement['dosage']),
          'color': supplement['color'],
        });
      }
    }
    
    return deficientList;
  }

  // 복용량 문자열을 숫자로 변환
  double _parseDosage(String dosageStr) {
    final regex = RegExp(r'(\d+(?:\.\d+)?)');
    final match = regex.firstMatch(dosageStr);
    if (match != null) {
      return double.parse(match.group(1)!);
    }
    return 0;
  }

  // AI 분석 실행
  Future<void> _performAIAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _analysisStep = '서버 연결 확인 중...';
      _analysisProgress = 0.1;
    });

    try {
      // 1. 서버 상태 확인
      final isServerHealthy = await ApiService.checkServerHealth();
      if (!isServerHealthy) {
        throw Exception('AI 서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
      }

      setState(() {
        _analysisStep = '건강검진 데이터 분석 중...';
        _analysisProgress = 0.3;
      });

      // 2. 건강검진 분석 (예시 데이터)
      final checkupResult = await ApiService.analyzeCheckup(
        name: widget.userData.name,
        age: int.tryParse(widget.userData.age) ?? 65,
        gender: widget.userData.gender,
        height: int.tryParse(widget.userData.height) ?? 170,
        weight: int.tryParse(widget.userData.weight) ?? 70,
        checkupText: '혈압 140/90, 콜레스테롤 220mg/dL, 혈당 110mg/dL',
      );

      setState(() {
        _analysisStep = '식단 데이터 준비 중...';
        _analysisProgress = 0.5;
      });

      // 3. 현재 섭취 영양소 분석
      final currentNutrients = _calculateNutrientsFromMeals();
      final deficientNutrients = _getDeficientNutrients();
      final excessiveNutrients = _getExcessiveNutrients();
      
      // 식단 분석 결과에 현재 섭취량 정보 추가
      final mealResult = {
        'content': '탄수화물 위주 식단으로 단백질과 비타민이 부족합니다.',
        'recommended_nutrient': deficientNutrients.isNotEmpty ? deficientNutrients.first['name'] : '단백질, 비타민 B12',
        'detected_foods': ['밥', '김치', '된장찌개'],
        'current_nutrients': currentNutrients,
        'deficient_nutrients': deficientNutrients.map((n) => n['name']).toList(),
        'excessive_nutrients': excessiveNutrients.map((n) => n['name']).toList(),
      };

      setState(() {
        _analysisStep = '개인 맞춤형 영양제 추천 중...';
        _analysisProgress = 0.7;
      });

      // 4. 스마트 영양제 추천 (빠른 추천 우선, RAG 분석은 백업)
      Map<String, dynamic> supplementResult;
      
      try {
        // 빠른 영양제 추천 우선 시도 (ThrottlingException 방지)
        setState(() {
          _analysisStep = '빠른 영양제 추천 중...';
          _analysisProgress = 0.8;
        });
        
        supplementResult = await ApiService.recommendSupplementsFast(
          name: widget.userData.name,
          age: int.tryParse(widget.userData.age) ?? 65,
          gender: widget.userData.gender,
          height: int.tryParse(widget.userData.height) ?? 170,
          weight: int.tryParse(widget.userData.weight) ?? 70,
          checkupResult: checkupResult,
          mealResult: mealResult,
        );
        
        print('✅ 빠른 영양제 추천 성공');
        
      } catch (fastError) {
        print('⚠️ 빠른 추천 실패, RAG 기반 분석 시도: $fastError');
        
        try {
          setState(() {
            _analysisStep = 'RAG 기반 상세 분석 중...';
            _analysisProgress = 0.85;
          });
          
          supplementResult = await ApiService.recommendSupplements(
            name: widget.userData.name,
            age: int.tryParse(widget.userData.age) ?? 65,
            gender: widget.userData.gender,
            height: int.tryParse(widget.userData.height) ?? 170,
            weight: int.tryParse(widget.userData.weight) ?? 70,
            checkupResult: checkupResult,
            mealResult: mealResult,
          );
          
          print('✅ RAG 기반 상세 영양제 추천 성공');
          
        } catch (ragError) {
          print('⚠️ 모든 API 실패, 스마트 로컬 추천 제공: $ragError');
          
          // 스마트 로컬 추천 (과다 섭취 영양소 제외)
          supplementResult = _generateSmartLocalRecommendation(
            deficientNutrients, 
            excessiveNutrients,
            checkupResult
          );
        }
      }

      setState(() {
        _analysisStep = '분석 결과 저장 중...';
        _analysisProgress = 0.95;
      });

      // Provider에 분석 결과 저장 (타임아웃 추가)
      if (mounted) {
        try {
          final analysisProvider = Provider.of<AnalysisProvider>(context, listen: false);
          
          // 5초 타임아웃으로 저장 시도
          await Future.any([
            analysisProvider.saveSupplementAnalysis(supplementResult),
            Future.delayed(const Duration(seconds: 5), () => throw Exception('저장 타임아웃'))
          ]);
          
          setState(() {
            _analysisStep = '분석 완료!';
            _analysisProgress = 1.0;
            _aiAnalysisResult = {
              'checkup': checkupResult,
              'meal': mealResult,
              'supplements': supplementResult,
            };
          });

          // 잠시 완료 메시지 표시 후 결과 다이얼로그 표시
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) {
            _showAIAnalysisResult();
            // 페이지 새로고침을 위해 setState 호출
            setState(() {});
          }
        } catch (saveError) {
          print('⚠️ 분석 결과 저장 실패, 결과만 표시: $saveError');
          
          // 저장 실패해도 결과는 표시
          setState(() {
            _analysisStep = '분석 완료! (저장 실패)';
            _analysisProgress = 1.0;
            _aiAnalysisResult = {
              'checkup': checkupResult,
              'meal': mealResult,
              'supplements': supplementResult,
            };
          });
          
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) {
            _showAIAnalysisResult();
            // 페이지 새로고침을 위해 setState 호출
            setState(() {});
          }
        }
      }

    } catch (e) {
      print('❌ AI 분석 오류: $e');
      
      // 더 자세한 오류 메시지 제공
      String errorMessage = 'AI 분석 중 오류가 발생했습니다';
      if (e.toString().contains('서버에 연결할 수 없습니다')) {
        errorMessage = 'AI 서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.';
      } else if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        errorMessage = '서버 응답 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = '네트워크 연결을 확인해주세요.';
      }
      
      if (mounted) {
        // 진행률을 100%로 완료 처리
        setState(() {
          _analysisStep = '분석 중단됨';
          _analysisProgress = 1.0;
        });
        
        // 잠시 후 에러 메시지 표시
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: '다시 시도',
                textColor: Colors.white,
                onPressed: () => _performAIAnalysis(),
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        // 항상 로딩 상태를 해제하고 진행률을 초기화
        setState(() {
          _isAnalyzing = false;
          _analysisStep = '';
          _analysisProgress = 0.0;
        });
      }
    }
  }

  // AI 분석 결과 다이얼로그
  void _showAIAnalysisResult() {
    if (_aiAnalysisResult == null) return;

    final supplements = _aiAnalysisResult!['supplements']['supplement_list'] as List;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🤖 AI 맞춤 영양제 추천'),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6, // 최대 높이 제한
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 종합 진단
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _aiAnalysisResult!['supplements']['content'] ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 추천 영양제 리스트
                const Text(
                  '추천 영양제:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                
                ...supplements.map((supplement) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supplement['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        supplement['reason'],
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        '복용: ${supplement['schedule']['time']} ${supplement['schedule']['timing']} (${supplement['dosage']})',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                )),
                
                // 주의사항
                if (_aiAnalysisResult!['supplements']['special_caution'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.yellow[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _aiAnalysisResult!['supplements']['special_caution'],
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // 권장량 범위에서 최소값과 최대값 추출
  Map<String, double> _parseRecommendedRange(String rangeStr) {
    final regex = RegExp(r'(\d+(?:\.\d+)?)-(\d+(?:\.\d+)?)');
    final match = regex.firstMatch(rangeStr);
    if (match != null) {
      return {
        'min': double.parse(match.group(1)!),
        'max': double.parse(match.group(2)!),
      };
    }
    // 단일 값인 경우 (예: "2.4mcg")
    final singleRegex = RegExp(r'(\d+(?:\.\d+)?)');
    final singleMatch = singleRegex.firstMatch(rangeStr);
    if (singleMatch != null) {
      final value = double.parse(singleMatch.group(1)!);
      return {'min': value, 'max': value * 2}; // 최대값을 임의로 2배로 설정
    }
    return {'min': 0, 'max': 0};
  }

  // 총 섭취량 기준으로 적정성 판단
  String _calculateAdequacyLevel(String supplementName, String dosageStr, String recommendedStr) {
    final totalIntake = _calculateTotalIntake(supplementName, dosageStr);
    final recommended = _parseRecommendedRange(recommendedStr);
    final total = totalIntake['total']!;
    final minRecommended = recommended['min']!;
    final maxRecommended = recommended['max']!;

    if (total < minRecommended * 0.8) {
      return '부족';
    } else if (total > maxRecommended * 1.2) {
      return '과다';
    } else {
      return '적정';
    }
  }

  // 복용량에서 단위 추출
  String _getUnit(String dosageStr) {
    if (dosageStr.contains('mg')) return 'mg';
    if (dosageStr.contains('IU')) return 'IU';
    if (dosageStr.contains('mcg')) return 'mcg';
    if (dosageStr.contains('CFU')) return '억 CFU';
    return '';
  }

  // 섭취량 상세 정보 위젯
  Widget _buildIntakeDetail(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getAdequacyColor(String adequacyLevel) {
    switch (adequacyLevel) {
      case '적정':
        return Colors.green;
      case '부족':
        return Colors.orange;
      case '과다':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getAdequacyIcon(String adequacyLevel) {
    switch (adequacyLevel) {
      case '적정':
        return Icons.check_circle;
      case '부족':
        return Icons.warning;
      case '과다':
        return Icons.error;
      default:
        return Icons.help;
    }
  }
  final List<Map<String, dynamic>> currentSupplements = [
    {
      'name': '오메가3',
      'dosage': '1000mg',
      'dailyRecommended': '1000-2000mg',
      'frequency': '1일 1회',
      'time': '아침 식후',
      'benefits': '심혈관 건강, 뇌 기능 개선',
      'color': Colors.orange,
    },
    {
      'name': '비타민D',
      'dosage': '2000IU',
      'dailyRecommended': '1000-4000IU',
      'frequency': '1일 1회',
      'time': '아침 식후',
      'benefits': '뼈 건강, 면역력 강화',
      'color': Colors.yellow,
    },
    {
      'name': '칼슘',
      'dosage': '500mg',
      'dailyRecommended': '1000-1200mg',
      'frequency': '1일 1회',
      'time': '저녁 식후',
      'benefits': '뼈와 치아 건강',
      'color': Colors.green,
    },
    {
      'name': '유산균',
      'dosage': '100억 CFU',
      'dailyRecommended': '100-500억 CFU',
      'frequency': '1일 1회',
      'time': '아침 공복',
      'benefits': '장 건강, 소화 개선',
      'color': Colors.purple,
    },
  ];

  List<Map<String, dynamic>> getAIRecommendedSupplements() {
    // AnalysisProvider에서 실제 AI 추천 결과 가져오기
    final analysisProvider = Provider.of<AnalysisProvider>(context, listen: false);
    final supplementAnalysis = analysisProvider.currentSupplementAnalysis;
    
    if (supplementAnalysis != null && supplementAnalysis['supplement_list'] != null) {
      // 실제 AI 추천 결과를 UI 형태로 변환
      final aiSupplements = supplementAnalysis['supplement_list'] as List<dynamic>;
      
      return aiSupplements.map<Map<String, dynamic>>((supplement) {
        // AI 추천 결과에서 색상 결정
        Color supplementColor = _getSupplementColor(supplement['name']);
        
        return {
          'name': supplement['name'],
          'reason': supplement['reason'],
          'dosage': supplement['dosage'],
          'dailyRecommended': _getRecommendedRange(supplement['name']),
          'benefits': supplement['benefits'] ?? _getSupplementBenefits(supplement['name']),
          'confidence': supplement['confidence'] ?? 85,
          'color': supplementColor,
          'basedOn': supplement['based_on'] ?? ['AI 종합 분석'],
          'aiAnalysis': supplement['detailed_analysis'] ?? supplement['reason'],
          'schedule': supplement['schedule'] ?? {'time': '1일 1회', 'timing': '식후'},
        };
      }).toList();
    }
    
    // AI 분석 결과가 없으면 기본 추천 (사용자 정보 기반)
    return _getDefaultRecommendations();
  }

  // 영양제별 색상 결정
  Color _getSupplementColor(String supplementName) {
    final colorMap = {
      '비타민 B12': Colors.red,
      '마그네슘': Colors.teal,
      '코엔자임 Q10': Colors.deepOrange,
      '칼륨': Colors.indigo,
      '레드 이스트 라이스': Colors.brown,
      '크롬 피콜리네이트': Colors.purple,
      '비타민 C': Colors.orange,
      '아연': Colors.blue,
      '철분': Colors.red[800]!,
      '엽산': Colors.green,
      '비타민 K': Colors.teal[700]!,
    };
    
    return colorMap[supplementName] ?? Colors.grey;
  }

  // 영양제별 권장량 범위
  String _getRecommendedRange(String supplementName) {
    final rangeMap = {
      '비타민 B12': '2.4-1000mcg',
      '마그네슘': '310-420mg',
      '코엔자임 Q10': '30-200mg',
      '칼륨': '3500-4700mg',
      '레드 이스트 라이스': '600-1200mg',
      '크롬 피콜리네이트': '25-200mcg',
      '비타민 C': '75-2000mg',
      '아연': '8-40mg',
      '철분': '8-45mg',
      '엽산': '400-1000mcg',
      '비타민 K': '90-120mcg',
    };
    
    return rangeMap[supplementName] ?? '권장량 확인 필요';
  }

  // 영양제별 효능
  String _getSupplementBenefits(String supplementName) {
    final benefitsMap = {
      '비타민 B12': '에너지 생성, 신경 건강, 혈액 생성',
      '마그네슘': '근육 이완, 수면 개선, 스트레스 완화',
      '코엔자임 Q10': '심장 건강, 항산화, 에너지 생산',
      '칼륨': '혈압 조절, 심장 건강, 근육 기능',
      '레드 이스트 라이스': '콜레스테롤 조절, 심혈관 건강',
      '크롬 피콜리네이트': '혈당 조절, 인슐린 기능 개선, 당분 대사',
      '비타민 C': '면역력 강화, 항산화, 콜라겐 합성',
      '아연': '면역 기능, 상처 치유, 단백질 합성',
      '철분': '산소 운반, 에너지 생성, 빈혈 예방',
      '엽산': '세포 분열, 혈액 생성, 신경관 발달',
      '비타민 K': '혈액 응고, 뼈 건강, 심혈관 건강',
    };
    
    return benefitsMap[supplementName] ?? '건강 유지에 도움';
  }

  // 과다 섭취 영양소 찾기
  List<Map<String, dynamic>> _getExcessiveNutrients() {
    final List<Map<String, dynamic>> excessiveList = [];
    
    for (var supplement in currentSupplements) {
      final adequacyLevel = _calculateAdequacyLevel(
        supplement['name'], 
        supplement['dosage'], 
        supplement['dailyRecommended']
      );
      
      if (adequacyLevel == '과다') {
        final totalIntake = _calculateTotalIntake(supplement['name'], supplement['dosage']);
        final recommended = _parseRecommendedRange(supplement['dailyRecommended']);
        
        excessiveList.add({
          'name': supplement['name'],
          'current': totalIntake['total']!,
          'recommended': recommended['max']!,
          'excess': totalIntake['total']! - recommended['max']!,
          'unit': _getUnit(supplement['dosage']),
          'color': supplement['color'],
        });
      }
    }
    
    return excessiveList;
  }

  // 스마트 로컬 추천 (과다 섭취 영양소 제외)
  Map<String, dynamic> _generateSmartLocalRecommendation(
    List<Map<String, dynamic>> deficientNutrients,
    List<Map<String, dynamic>> excessiveNutrients,
    Map<String, dynamic> checkupResult
  ) {
    List<Map<String, dynamic>> smartRecommendations = [];
    
    // 과다 섭취 영양소 이름 목록
    final excessiveNames = excessiveNutrients.map((n) => n['name'] as String).toSet();
    
    // 부족한 영양소 중에서 과다 섭취가 아닌 것만 추천
    for (var deficient in deficientNutrients) {
      final nutrientName = deficient['name'] as String;
      
      if (!excessiveNames.contains(nutrientName)) {
        smartRecommendations.add({
          'name': nutrientName,
          'reason': '현재 ${deficient['deficit'].toStringAsFixed(0)}${deficient['unit']} 부족하여 보충이 필요합니다',
          'dosage': '${deficient['deficit'].toStringAsFixed(0)}${deficient['unit']}',
          'schedule': {'time': '아침', 'timing': '식후'},
          'benefits': _getSupplementBenefits(nutrientName),
          'confidence': 85,
          'based_on': ['식단 분석', '현재 섭취량 계산'],
        });
      }
    }
    
    // 나이대별 기본 추천 (과다 섭취가 아닌 경우만)
    final age = int.tryParse(widget.userData.age) ?? 65;
    
    if (age >= 50 && !excessiveNames.contains('비타민 B12')) {
      smartRecommendations.add({
        'name': '비타민 B12',
        'reason': '50세 이상 연령대에서 흡수율이 감소하여 보충이 필요합니다',
        'dosage': '1000mcg',
        'schedule': {'time': '아침', 'timing': '식후'},
        'benefits': '에너지 생성, 신경 건강, 혈액 생성',
        'confidence': 90,
        'based_on': ['연령대 분석'],
      });
    }
    
    if (!excessiveNames.contains('비타민D')) {
      smartRecommendations.add({
        'name': '비타민D',
        'reason': '면역력 강화와 뼈 건강을 위해 필요합니다',
        'dosage': '1000IU',
        'schedule': {'time': '아침', 'timing': '식후'},
        'benefits': '뼈 건강, 면역력 강화, 근육 기능',
        'confidence': 88,
        'based_on': ['기본 건강 관리'],
      });
    }
    
    // 건강 관심사 기반 추천
    final concerns = widget.userData.healthConcerns;
    
    if (concerns.contains('혈압') && !excessiveNames.contains('마그네슘')) {
      smartRecommendations.add({
        'name': '마그네슘',
        'reason': '혈압 조절과 심혈관 건강을 위해 필요합니다',
        'dosage': '400mg',
        'schedule': {'time': '저녁', 'timing': '식후'},
        'benefits': '혈압 조절, 근육 이완, 스트레스 완화',
        'confidence': 85,
        'based_on': ['건강 관심사'],
      });
    }
    
    // 과다 섭취 경고 메시지 생성
    String cautionMessage = '';
    if (excessiveNutrients.isNotEmpty) {
      final excessiveNamesList = excessiveNutrients.map((n) => n['name']).join(', ');
      cautionMessage = '현재 $excessiveNamesList 섭취량이 권장량을 초과하고 있어 추천에서 제외했습니다. ';
    }
    
    return {
      'content': '${widget.userData.name}님의 현재 섭취량을 분석하여 과다 섭취 영양소를 제외한 스마트 추천을 제공합니다.',
      'status': 'Green',
      'supplement_list': smartRecommendations,
      'special_caution': cautionMessage + '현재 복용 중인 약물이 있다면 의사와 상담 후 복용하세요.',
      'excluded_nutrients': excessiveNames.toList(),
      'smart_filtering': true,
    };
  }

  // 기본 추천 (AI 분석 결과가 없을 때)
  List<Map<String, dynamic>> _getDefaultRecommendations() {
    List<Map<String, dynamic>> recommendations = [];

    // 나이대별 기본 추천
    final age = int.tryParse(widget.userData.age) ?? 65;
    
    if (age >= 50) {
      recommendations.addAll([
        {
          'name': '비타민 B12',
          'reason': '50세 이상 연령대 필수 영양소',
          'dosage': '1000mcg',
          'dailyRecommended': '2.4-1000mcg',
          'benefits': '에너지 생성, 신경 건강, 혈액 생성',
          'confidence': 90,
          'color': Colors.red,
          'basedOn': ['연령대 분석'],
          'aiAnalysis': '50세 이상에서는 B12 흡수율이 감소하여 보충이 필요합니다.',
        },
        {
          'name': '비타민 D',
          'reason': '뼈 건강과 면역력 강화',
          'dosage': '2000IU',
          'dailyRecommended': '1000-4000IU',
          'benefits': '뼈 건강, 면역력 강화, 근육 기능',
          'confidence': 88,
          'color': Colors.yellow[700]!,
          'basedOn': ['연령대 분석'],
          'aiAnalysis': '실내 활동이 많은 경우 비타민 D 부족이 흔합니다.',
        },
      ]);
    }

    // 건강 관심사 기반 추천
    final concerns = widget.userData.healthConcerns;
    
    if (concerns.contains('혈압')) {
      recommendations.add({
        'name': '마그네슘',
        'reason': '혈압 조절과 심혈관 건강',
        'dosage': '400mg',
        'dailyRecommended': '310-420mg',
        'benefits': '혈압 조절, 근육 이완, 스트레스 완화',
        'confidence': 85,
        'color': Colors.teal,
        'basedOn': ['건강 관심사'],
        'aiAnalysis': '마그네슘은 자연스러운 혈압 조절에 도움을 줍니다.',
      });
    }

    if (concerns.contains('콜레스테롤')) {
      recommendations.add({
        'name': '코엔자임 Q10',
        'reason': '심혈관 건강과 항산화',
        'dosage': '100mg',
        'dailyRecommended': '30-200mg',
        'benefits': '심장 건강, 항산화, 에너지 생산',
        'confidence': 82,
        'color': Colors.deepOrange,
        'basedOn': ['건강 관심사'],
        'aiAnalysis': '콜레스테롤 관리와 함께 심장 건강을 지원합니다.',
      });
    }

    return recommendations;
  }

  @override
  void dispose() {
    // 진행 중인 비동기 작업이 있다면 정리
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '영양제 관리',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Consumer<AnalysisProvider>(
        builder: (context, analysisProvider, child) {
          final aiRecommendedSupplements = getAIRecommendedSupplements();
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // 최근 영양제 분석 결과 표시
            const PersistentAnalysisWidget(
              title: '영양제',
              type: 'supplement',
            ),
            
            // AI 분석 버튼
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _performAIAnalysis,
                    icon: _isAnalyzing 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.psychology, color: Colors.white),
                    label: Text(
                      _isAnalyzing ? _analysisStep.isNotEmpty ? _analysisStep : 'AI 분석 중...' : '🤖 AI 맞춤 영양제 분석',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3), // 파란색
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                  if (_isAnalyzing && _analysisProgress > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _analysisProgress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(_analysisProgress * 100).toInt()}% 완료',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // 오늘 섭취한 영양소
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.restaurant, color: Colors.green, size: 24),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '오늘 섭취한 영양소',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '식단 + 영양제 종합',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...currentSupplements.map((supplement) {
                    final adequacyLevel = _calculateAdequacyLevel(
                      supplement['name'], 
                      supplement['dosage'], 
                      supplement['dailyRecommended']
                    );
                    final totalIntake = _calculateTotalIntake(supplement['name'], supplement['dosage']);
                    final recommended = _parseRecommendedRange(supplement['dailyRecommended']);
                    final progressValue = (totalIntake['total']! / recommended['max']!).clamp(0.0, 1.0);
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: supplement['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: supplement['color'].withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 헤더 (이름 + 적정성)
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: supplement['color'],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  supplement['name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getAdequacyColor(adequacyLevel).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getAdequacyColor(adequacyLevel),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getAdequacyIcon(adequacyLevel),
                                      size: 14,
                                      color: _getAdequacyColor(adequacyLevel),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      adequacyLevel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _getAdequacyColor(adequacyLevel),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // 총 섭취량 vs 권장량 (큰 텍스트)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '총 섭취량',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '${totalIntake['total']!.toStringAsFixed(0)}${_getUnit(supplement['dosage'])}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '권장량',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    supplement['dailyRecommended'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // 진행률 바
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '권장량 대비',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '${(progressValue * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _getAdequacyColor(adequacyLevel),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: progressValue,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getAdequacyColor(adequacyLevel),
                                ),
                                minHeight: 6,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // 섭취 구성 (식단 vs 영양제)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: totalIntake['food']!.toInt(),
                                  child: Container(
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.green[300],
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        bottomLeft: Radius.circular(4),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '식단',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (totalIntake['supplement']! > 0)
                                  Expanded(
                                    flex: totalIntake['supplement']!.toInt(),
                                    child: Container(
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: supplement['color'],
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(4),
                                          bottomRight: Radius.circular(4),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '영양제',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // 상세 수치
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildIntakeDetail(
                                '식단',
                                '${totalIntake['food']!.toStringAsFixed(0)}${_getUnit(supplement['dosage'])}',
                                Colors.green[300]!,
                              ),
                              _buildIntakeDetail(
                                '영양제',
                                supplement['dosage'],
                                supplement['color'],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // 복용 정보
                          Text(
                            '${supplement['frequency']} • ${supplement['time']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            supplement['benefits'],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 부족한 영양소 경고
            if (_getDeficientNutrients().isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[300]!, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.info_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '부족한 영양소',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '권장량보다 부족하게 섭취하고 있어요',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._getDeficientNutrients().map((nutrient) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: nutrient['color'].withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: nutrient['color'],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  nutrient['name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${(nutrient['deficit'] as double).toStringAsFixed(0)}${nutrient['unit']} 부족',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '현재 섭취량',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '${(nutrient['current'] as double).toStringAsFixed(0)}${nutrient['unit']}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(Icons.arrow_forward, color: Colors.grey[400]),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '권장 섭취량',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '${(nutrient['recommended'] as double).toStringAsFixed(0)}${nutrient['unit']}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (nutrient['current'] as double) / (nutrient['recommended'] as double),
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            minHeight: 6,
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ),

            // AI 추천 영양제
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.purple, Colors.blue],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI 맞춤 추천 영양제',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '식단, 건강검진, 복용 영양제를 종합 분석',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  ...aiRecommendedSupplements.map((supplement) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          supplement['color'].withOpacity(0.1),
                          supplement['color'].withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: supplement['color'].withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: supplement['color'],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    supplement['name'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    supplement['reason'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${supplement['confidence']}% 추천',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getAdequacyColor(_calculateAdequacyLevel(
                                      supplement['name'], 
                                      supplement['dosage'], 
                                      supplement['dailyRecommended']
                                    )).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getAdequacyIcon(_calculateAdequacyLevel(
                                          supplement['name'], 
                                          supplement['dosage'], 
                                          supplement['dailyRecommended']
                                        )),
                                        size: 10,
                                        color: _getAdequacyColor(_calculateAdequacyLevel(
                                          supplement['name'], 
                                          supplement['dosage'], 
                                          supplement['dailyRecommended']
                                        )),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        _calculateAdequacyLevel(
                                          supplement['name'], 
                                          supplement['dosage'], 
                                          supplement['dailyRecommended']
                                        ),
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: _getAdequacyColor(_calculateAdequacyLevel(
                                            supplement['name'], 
                                            supplement['dosage'], 
                                            supplement['dailyRecommended']
                                          )),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // AI 분석 내용
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.psychology, size: 16, color: Colors.blue[600]),
                                  const SizedBox(width: 6),
                                  Text(
                                    'AI 분석',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                supplement['aiAnalysis'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // 효능과 권장량 (간소화)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '권장 복용량: ${supplement['dosage']} (권장: ${supplement['dailyRecommended']})',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              supplement['benefits'],
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${supplement['name']} 복용 목록에 추가됨'),
                                  backgroundColor: supplement['color'],
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: supplement['color'],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              '복용 목록에 추가',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ],
        ),
      );
        }
      ),
    );
  }
}