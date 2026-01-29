import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import '../models/user_data.dart';
import '../services/api_service.dart';
import '../providers/analysis_provider.dart';
import '../providers/meal_data_provider.dart';

class DietPage extends StatefulWidget {
  final UserData userData;

  const DietPage({super.key, required this.userData});

  @override
  State<DietPage> createState() => _DietPageState();
}

class _DietPageState extends State<DietPage> with TickerProviderStateMixin {
  DateTime currentWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday % 7));
  DateTime selectedDate = DateTime.now();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final List<String> weekDays = ['일', '월', '화', '수', '목', '금', '토'];

  List<DateTime> _getWeekDates() {
    return List.generate(7, (index) => currentWeekStart.add(Duration(days: index)));
  }

  void _previousWeek() {
    setState(() {
      currentWeekStart = currentWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      currentWeekStart = currentWeekStart.add(const Duration(days: 7));
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      selectedDate = date;
    });
  }

  String _getMealTypeFromTime(String time) {
    final hour = int.parse(time.split(':')[0]);
    if (hour < 11) return '아침';
    if (hour < 17) return '점심';
    return '저녁';
  }

  Color _getMealColor(String mealType) {
    switch (mealType) {
      case '아침':
        return Colors.orange;
      case '점심':
        return Colors.green;
      case '저녁':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getMealIcon(String mealType) {
    switch (mealType) {
      case '아침':
        return Icons.wb_sunny;
      case '점심':
        return Icons.wb_sunny_outlined;
      case '저녁':
        return Icons.nightlight_round;
      default:
        return Icons.restaurant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekDates = _getWeekDates();

    return Consumer2<MealDataProvider, AnalysisProvider>(
      builder: (context, mealProvider, analysisProvider, child) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text(
              '식단 관리',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 주간 네비게이션
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: _previousWeek,
                            icon: const Icon(Icons.chevron_left, size: 28),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${DateFormat('M월 d일').format(currentWeekStart)} ~ ${DateFormat('M월 d일').format(weekDates[6])}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            onPressed: _nextWeek,
                            icon: const Icon(Icons.chevron_right, size: 28),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 주간 캘린더
                      Row(
                        children: weekDates.asMap().entries.map((entry) {
                          final index = entry.key;
                          final date = entry.value;
                          final dateKey = DateFormat('yyyy-MM-dd').format(date);
                          final meals = mealProvider.getMealsForDate(dateKey);
                          final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateKey;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _selectDate(date),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: DateFormat('yyyy-MM-dd').format(selectedDate) == dateKey
                                      ? const Color(0xFFF3F9FF) // 연한 파란색으로 변경
                                      : isToday 
                                          ? const Color(0xFFF8FBFF) // 더 연한 파란색으로 변경
                                          : Colors.white,
                                  border: Border.all(
                                    color: DateFormat('yyyy-MM-dd').format(selectedDate) == dateKey
                                        ? const Color(0xFF2196F3) // 파란색으로 변경
                                        : isToday 
                                            ? const Color(0xFFBBDEFB) // 연한 파란색으로 변경
                                            : Colors.grey[200]!,
                                    width: DateFormat('yyyy-MM-dd').format(selectedDate) == dateKey ? 3 : 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      weekDays[index],
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: DateFormat('yyyy-MM-dd').format(selectedDate) == dateKey
                                            ? const Color(0xFF2196F3) // 파란색으로 변경
                                            : isToday 
                                                ? const Color(0xFF64B5F6) // 연한 파란색으로 변경
                                                : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${date.day}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: DateFormat('yyyy-MM-dd').format(selectedDate) == dateKey
                                            ? const Color(0xFF2196F3) // 파란색으로 변경
                                            : isToday 
                                                ? const Color(0xFF64B5F6) // 연한 파란색으로 변경
                                                : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // 식사 표시
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildMealIndicator(meals, '아침'),
                                        const SizedBox(width: 2),
                                        _buildMealIndicator(meals, '점심'),
                                        const SizedBox(width: 2),
                                        _buildMealIndicator(meals, '저녁'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 식사 사진 추가 버튼
                Container(
                  width: double.infinity,
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
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showAddMealDialog(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2196F3), Color(0xFF64B5F6)], // 파란색 그라데이션으로 변경
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.add_a_photo,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('yyyy-MM-dd').format(selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now())
                                        ? '오늘의 식사 추가하기'
                                        : '${DateFormat('M월 d일').format(selectedDate)} 식사 추가하기',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '카메라로 촬영하거나 갤러리에서 선택하세요',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 탭 컨테이너
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
                  child: Column(
                    children: [
                      // 탭 헤더
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: const Color(0xFF2196F3), // 파란색으로 변경
                          unselectedLabelColor: Colors.grey[600],
                          indicatorColor: const Color(0xFF2196F3), // 파란색으로 변경
                          indicatorWeight: 3,
                          labelStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.restaurant, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('yyyy-MM-dd').format(selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now())
                                        ? '오늘의 식단'
                                        : '${DateFormat('M/d').format(selectedDate)} 식단',
                                  ),
                                ],
                              ),
                            ),
                            const Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.psychology, size: 20),
                                  SizedBox(width: 8),
                                  Text('AI 분석결과'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // 탭 내용
                      SizedBox(
                        height: 400, // 고정 높이 설정
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // 첫 번째 탭: 오늘의 식단
                            _buildMealListTab(mealProvider),
                            
                            // 두 번째 탭: AI 분석결과
                            _buildAnalysisTab(analysisProvider),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMealListTab(MealDataProvider mealProvider) {
    final selectedDateMeals = _getSelectedDateMeals(mealProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('yyyy-MM-dd').format(selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now())
                    ? '오늘 섭취한 음식'
                    : '${DateFormat('M월 d일').format(selectedDate)} 섭취한 음식',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (selectedDateMeals.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '총 ${_getTotalCalories(mealProvider)}kcal',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          Expanded(
            child: selectedDateMeals.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          DateFormat('yyyy-MM-dd').format(selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now())
                              ? '오늘 등록된 식단이 없습니다.\n식사 사진을 추가해보세요!'
                              : '${DateFormat('M월 d일').format(selectedDate)}에 등록된 식단이 없습니다.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: selectedDateMeals.length,
                    itemBuilder: (context, index) {
                      final meal = selectedDateMeals[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getMealColor(meal['type']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getMealColor(meal['type']).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _getMealColor(meal['type']),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getMealIcon(meal['type']),
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        meal['type'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        meal['time'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${meal['calories']}kcal',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _getMealColor(meal['type']),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: _getFoodsList(meal['foods']).map((food) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Text(
                                  food,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              )).toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab(AnalysisProvider analysisProvider) {
    final mealAnalysis = analysisProvider.currentMealAnalysis;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: mealAnalysis == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'AI 분석 결과가 없습니다.\n식사 사진을 추가하면 AI가 분석해드려요!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI 분석 헤더
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.purple, Colors.purpleAccent],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '최근 AI 분석 결과',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '저장됨',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 인식된 음식들
                  if (mealAnalysis['detected_foods'] != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.restaurant, color: Colors.orange[600], size: 16),
                              const SizedBox(width: 8),
                              const Text(
                                '인식된 음식',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: (mealAnalysis['detected_foods'] as List<dynamic>)
                                .map((food) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        food.toString(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange[800],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // AI 분석 내용
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.analytics, color: Colors.blue[600], size: 16),
                            const SizedBox(width: 8),
                            const Text(
                              'AI 영양 분석',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mealAnalysis['content'] ?? '분석 결과가 없습니다.',
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 추천사항이 있다면 표시
                  if (mealAnalysis['recommendations'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb, color: Colors.green[600], size: 16),
                              const SizedBox(width: 8),
                              const Text(
                                'AI 추천사항',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mealAnalysis['recommendations'].toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildMealIndicator(List<Map<String, dynamic>> meals, String mealType) {
    final hasMeal = meals.any((meal) => meal['type'] == mealType);
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: hasMeal ? _getMealColor(mealType) : Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }

  List<Map<String, dynamic>> _getSelectedDateMeals(MealDataProvider mealProvider) {
    final selectedDateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
    return mealProvider.getMealsForDate(selectedDateKey);
  }

  int _getTotalCalories(MealDataProvider mealProvider) {
    final selectedDateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
    return mealProvider.getTotalCaloriesForDate(selectedDateKey);
  }

  // 안전한 타입 변환을 위한 헬퍼 메서드
  List<String> _getFoodsList(dynamic foods) {
    if (foods is List<String>) {
      return foods;
    } else if (foods is List) {
      return foods.map((item) => item.toString()).toList();
    } else {
      return [];
    }
  }

  // AI 음식 인식 결과 표시
  // AI 음식 인식 결과 표시
  void _showFoodRecognitionResult(bool isCamera) async {
    try {
      // 이미지 선택
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: isCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      // 로딩 다이얼로그 표시
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('AI가 음식을 분석하고 있습니다...'),
                const SizedBox(height: 8),
                Text(
                  '잠시만 기다려주세요 (최대 30초)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      try {
        // 실제 AI 분석 호출
        final imageFile = File(image.path);
        final base64Image = ApiService.encodeImageToBase64(imageFile);
        
        print('🔍 식단 분석 시작: ${widget.userData.name}');
        
        final result = await ApiService.analyzeMeal(
          name: widget.userData.name,
          age: int.tryParse(widget.userData.age) ?? 65,
          gender: widget.userData.gender,
          height: int.tryParse(widget.userData.height) ?? 170,
          weight: int.tryParse(widget.userData.weight) ?? 70,
          imageBase64: base64Image,
        );

        print('✅ 식단 분석 완료: ${result['detected_foods']}');

        // 로딩 다이얼로그 닫기
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

        // Provider에 분석 결과 저장
        if (mounted) {
          try {
            final analysisProvider = Provider.of<AnalysisProvider>(context, listen: false);
            await analysisProvider.saveMealAnalysis(result, image.path);
            print('✅ 분석 결과 저장 완료');
          } catch (saveError) {
            print('⚠️ 분석 결과 저장 실패: $saveError');
            // 저장 실패해도 계속 진행
          }
        }

        // AI 분석 결과를 음식 인식 형태로 변환
        final recognizedFoods = _convertAIResultToFoodList(result);
        
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => _FoodRecognitionDialog(
              recognizedFoods: recognizedFoods,
              selectedDate: selectedDate,
              aiAnalysisResult: result,
              onMealAdded: (meal) async {
                final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
                print('🍽️ 식단 추가 시도: $dateKey, 식사: ${meal['type']}, 음식: ${meal['foods']}');
                
                // 현재 context를 미리 저장
                final currentContext = context;
                final currentMounted = mounted;
                
                try {
                  final mealProvider = Provider.of<MealDataProvider>(currentContext, listen: false);
                  await mealProvider.addMealToDate(dateKey, meal);
                  
                  print('✅ 식단 추가 완료: $dateKey');
                  
                  // UI 새로고침을 위해 setState 호출
                  if (currentMounted && mounted) {
                    setState(() {});
                    
                    // 성공 메시지 표시 - context 유효성 재확인
                    if (mounted && currentContext.mounted) {
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 8),
                              Text('${meal['type']} 식단이 성공적으로 추가되었습니다!'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                } catch (addError) {
                  print('❌ 식단 추가 실패: $addError');
                  if (currentMounted && mounted && currentContext.mounted) {
                    String errorMessage = '식단 추가 중 오류가 발생했습니다';
                    
                    // 에러 타입에 따른 구체적인 메시지
                    if (addError.toString().contains('SharedPreferences')) {
                      errorMessage = '로컬 저장소 접근 오류입니다. 앱을 다시 시작해보세요.';
                    } else if (addError.toString().contains('JSON')) {
                      errorMessage = '데이터 형식 오류입니다. 다시 시도해주세요.';
                    } else if (addError.toString().contains('null')) {
                      errorMessage = '필수 데이터가 누락되었습니다. 다시 시도해주세요.';
                    }
                    
                    try {
                      ScaffoldMessenger.of(currentContext).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.white),
                              const SizedBox(width: 8),
                              Expanded(child: Text(errorMessage)),
                            ],
                          ),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 4),
                          action: SnackBarAction(
                            label: '다시 시도',
                            textColor: Colors.white,
                            onPressed: () async {
                              // 다시 시도 - 위젯이 여전히 마운트되어 있는지 확인
                              if (!mounted || !currentContext.mounted) return;
                              
                              try {
                                final retryMealProvider = Provider.of<MealDataProvider>(currentContext, listen: false);
                                await retryMealProvider.addMealToDate(dateKey, meal);
                                
                                if (mounted && currentContext.mounted) {
                                  setState(() {});
                                  ScaffoldMessenger.of(currentContext).showSnackBar(
                                    const SnackBar(
                                      content: Text('식단이 성공적으로 추가되었습니다!'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (retryError) {
                                print('❌ 재시도도 실패: $retryError');
                                if (mounted && currentContext.mounted) {
                                  ScaffoldMessenger.of(currentContext).showSnackBar(
                                    const SnackBar(
                                      content: Text('재시도에도 실패했습니다. 앱을 다시 시작해보세요.'),
                                      backgroundColor: Colors.red,
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      );
                    } catch (scaffoldError) {
                      print('❌ ScaffoldMessenger 접근 실패: $scaffoldError');
                    }
                  }
                }
              },
            ),
          );
        }

      } catch (apiError) {
        print('❌ API 호출 오류: $apiError');
        
        // 로딩 다이얼로그 닫기
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
        
        // 에러 메시지 표시
        if (mounted) {
          String errorMessage = '음식 분석 중 오류가 발생했습니다';
          if (apiError.toString().contains('timeout') || apiError.toString().contains('TimeoutException')) {
            errorMessage = '서버 응답 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.';
          } else if (apiError.toString().contains('SocketException')) {
            errorMessage = '네트워크 연결을 확인해주세요.';
          } else if (apiError.toString().contains('서버')) {
            errorMessage = 'AI 서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.';
          } else if (apiError.toString().contains('Connection refused')) {
            errorMessage = 'AI 서버가 실행되지 않았습니다. 서버를 시작해주세요.';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(errorMessage)),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: '다시 시도',
                textColor: Colors.white,
                onPressed: () => _showFoodRecognitionResult(isCamera),
              ),
            ),
          );
        }
      }

    } catch (e) {
      print('❌ 전체 프로세스 오류: $e');
      
      // 로딩 다이얼로그가 열려있다면 닫기
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        String errorMessage = '예상치 못한 오류가 발생했습니다';
        if (e.toString().contains('Permission')) {
          errorMessage = '카메라 또는 갤러리 접근 권한이 필요합니다.';
        } else if (e.toString().contains('ImagePicker')) {
          errorMessage = '이미지 선택 중 오류가 발생했습니다. 다시 시도해주세요.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // AI 분석 결과를 음식 리스트로 변환
  List<Map<String, dynamic>> _convertAIResultToFoodList(Map<String, dynamic> aiResult) {
    final detectedFoods = aiResult['detected_foods'] as List<dynamic>? ?? [];
    
    if (detectedFoods.isEmpty) {
      // 음식이 인식되지 않은 경우 기본 옵션 제공
      return [
        {
          'name': '인식된 음식',
          'portions': [
            {'label': '적게', 'calories': 200},
            {'label': '보통', 'calories': 400},
            {'label': '많이', 'calories': 600},
          ],
        }
      ];
    }

    // 인식된 음식들을 포션 선택 형태로 변환
    return detectedFoods.map<Map<String, dynamic>>((food) {
      final foodName = food.toString();
      
      // 음식 종류에 따른 포션 옵션 생성
      List<Map<String, dynamic>> portions;
      
      if (foodName.contains('밥') || foodName.contains('rice')) {
        portions = [
          {'label': '반 공기', 'calories': 150},
          {'label': '한 공기', 'calories': 300},
          {'label': '두 공기', 'calories': 600},
        ];
      } else if (foodName.contains('찌개') || foodName.contains('국') || foodName.contains('soup')) {
        portions = [
          {'label': '반 그릇', 'calories': 120},
          {'label': '한 그릇', 'calories': 240},
          {'label': '큰 그릇', 'calories': 360},
        ];
      } else if (foodName.contains('고기') || foodName.contains('meat')) {
        portions = [
          {'label': '작은 조각', 'calories': 150},
          {'label': '보통 조각', 'calories': 250},
          {'label': '큰 조각', 'calories': 400},
        ];
      } else {
        portions = [
          {'label': '조금', 'calories': 50},
          {'label': '보통', 'calories': 100},
          {'label': '많이', 'calories': 200},
        ];
      }

      return {
        'name': foodName,
        'portions': portions,
      };
    }).toList();
  }

  void _showAddMealDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 핸들바
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              DateFormat('yyyy-MM-dd').format(selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now())
                  ? '오늘의 식사 사진 추가'
                  : '${DateFormat('M월 d일 (E)', 'ko_KR').format(selectedDate)} 식사 사진 추가',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI가 사진에서 음식을 인식하고, 양은 직접 선택하세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // 카메라 촬영 버튼
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _showFoodRecognitionResult(true); // 카메라로 촬영
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.blueAccent],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 28, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      '카메라로 촬영하기',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 갤러리 선택 버튼
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _showFoodRecognitionResult(false); // 갤러리에서 선택
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_library, size: 28, color: Colors.grey[700]),
                    const SizedBox(width: 12),
                    Text(
                      '갤러리에서 선택하기',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 안내 텍스트
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '더 정확한 인식을 위한 팁',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 음식이 잘 보이도록 위에서 촬영하세요\n• 숟가락이나 젓가락을 함께 찍으면 크기 비교에 도움됩니다\n• 각 음식이 겹치지 않게 촬영하세요',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 음식 인식 결과 다이얼로그
class _FoodRecognitionDialog extends StatefulWidget {
  final List<Map<String, dynamic>> recognizedFoods;
  final DateTime selectedDate;
  final Function(Map<String, dynamic>) onMealAdded;
  final Map<String, dynamic>? aiAnalysisResult;

  const _FoodRecognitionDialog({
    required this.recognizedFoods,
    required this.selectedDate,
    required this.onMealAdded,
    this.aiAnalysisResult,
  });

  @override
  State<_FoodRecognitionDialog> createState() => _FoodRecognitionDialogState();
}

class _FoodRecognitionDialogState extends State<_FoodRecognitionDialog> {
  Map<String, Map<String, dynamic>> selectedPortions = {};
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 핸들바
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // 제목
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.smart_toy,
                  color: Colors.green[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'AI가 인식한 음식',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '각 음식의 양을 선택해주세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // 인식된 음식 리스트
          Expanded(
            child: ListView.builder(
              itemCount: widget.recognizedFoods.length,
              itemBuilder: (context, index) {
                final food = widget.recognizedFoods[index];
                final foodName = food['name'] as String;
                final portions = food['portions'] as List<Map<String, dynamic>>;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 음식 이름
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.restaurant,
                              color: Colors.orange[600],
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            foodName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // 양 선택 버튼들
                      Text(
                        '양 선택:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: portions.map((portion) {
                          final isSelected = selectedPortions[foodName] == portion;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedPortions[foodName] = portion;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blue[500] : Colors.white,
                                border: Border.all(
                                  color: isSelected ? Colors.blue[500]! : Colors.grey[300]!,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    portion['label'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '(${portion['calories']}kcal)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected ? Colors.white70 : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 하단 버튼들
          const SizedBox(height: 16),
          Row(
            children: [
              // 취소 버튼
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // 식단에 추가 버튼
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: selectedPortions.isEmpty ? null : _addMealToCalendar,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: selectedPortions.isEmpty 
                          ? null 
                          : const LinearGradient(
                              colors: [Colors.green, Colors.greenAccent],
                            ),
                      color: selectedPortions.isEmpty ? Colors.grey[300] : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: selectedPortions.isEmpty ? Colors.grey[600] : Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '식단에 추가 (${_getTotalSelectedCalories()}kcal)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: selectedPortions.isEmpty ? Colors.grey[600] : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // 안내 텍스트
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI 인식 결과는 참고용입니다. 실제 섭취량과 다를 수 있어요.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getTotalSelectedCalories() {
    return selectedPortions.values.fold(0, (total, portion) => total + (portion['calories'] as int));
  }

  void _addMealToCalendar() {
    if (selectedPortions.isEmpty) return;

    // 현재 시간을 기준으로 식사 타입 결정
    final now = DateTime.now();
    String mealType;
    if (now.hour < 11) {
      mealType = '아침';
    } else if (now.hour < 17) {
      mealType = '점심';
    } else {
      mealType = '저녁';
    }

    // 선택된 음식들로 식사 데이터 생성
    final meal = {
      'type': mealType,
      'time': DateFormat('HH:mm').format(now),
      'foods': selectedPortions.keys.map((foodName) {
        final portion = selectedPortions[foodName]!;
        return '$foodName (${portion['label']})';
      }).toList(),
      'image': 'user_added_${DateTime.now().millisecondsSinceEpoch}.jpg',
      'calories': _getTotalSelectedCalories(),
    };

    // 식단에 추가 (성공 메시지는 onMealAdded 콜백에서 처리)
    widget.onMealAdded(meal);
    
    // 다이얼로그 닫기
    Navigator.pop(context);
  }
}