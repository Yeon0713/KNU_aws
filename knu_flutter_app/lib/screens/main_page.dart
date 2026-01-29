import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/user_data.dart';
import '../services/api_service.dart';
import '../providers/analysis_provider.dart';
import '../providers/meal_data_provider.dart';
import '../providers/medication_provider.dart';

class MainPage extends StatefulWidget {
  final UserData userData;

  const MainPage({super.key, required this.userData});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final TextEditingController _factCheckController = TextEditingController();

  final List<String> weekDays = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  void initState() {
    super.initState();
  }

  List<DateTime> _getWeekDates(DateTime weekStart) {
    return List.generate(7, (index) => weekStart.add(Duration(days: index)));
  }

  Color _getMealColor(String mealType) {
    switch (mealType) {
      case '아침':
        return const Color(0xFF64B5F6); // 연한 파란색으로 변경
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

  void _showFactCheckDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.1), // 파란색으로 변경
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.shield_outlined, color: const Color(0xFF2196F3), size: 24), // 파란색으로 변경
                ),
                const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '건강 정보 팩트체크',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '의심스러운 건강 정보를 확인해드려요',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600, // 글씨 두께 더 증가
                            color: Colors.grey.shade800, // 색상을 더욱 진하게
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '확인하고 싶은 건강 정보를 입력해주세요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _factCheckController,
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(
                    hintText: '예시:\n• "양파즙이 당뇨에 특효래"\n• "이 영양제 먹으면 암이 낫는다더라"\n• 유튜브 링크: https://youtube.com/...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade600, // 힌트 텍스트 색상 진하게
                      fontSize: 14,
                      fontWeight: FontWeight.w500, // 힌트 텍스트 두께 증가
                      height: 1.5,
                    ),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      final inputText = _factCheckController.text.trim();
                      if (inputText.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('확인할 내용을 입력해주세요.')),
                        );
                        return;
                      }
                      
                      Navigator.pop(context);
                      await _performFactCheck(inputText);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3), // 파란색으로 변경
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '팩트체크 시작',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performFactCheck(String inputText) async {
    try {
      final isYouTubeUrl = inputText.contains('youtube.com') || inputText.contains('youtu.be');
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                isYouTubeUrl 
                  ? 'AI가 유튜브 영상을 분석하고 있습니다...\n시간이 오래 걸릴 수 있습니다.'
                  : 'AI가 건강 정보를 검증하고 있습니다...',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              if (isYouTubeUrl) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '유튜브 자막 분석 중...',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
          ],
        ),
      );

      Map<String, dynamic> result;
      
      if (isYouTubeUrl) {
        result = await ApiService.factCheckYoutube(
          name: widget.userData.name,
          age: int.tryParse(widget.userData.age) ?? 65,
          gender: widget.userData.gender,
          height: int.tryParse(widget.userData.height) ?? 170,
          weight: int.tryParse(widget.userData.weight) ?? 70,
          youtubeUrl: inputText,
        );
      } else {
        result = await ApiService.factCheckYoutube(
          name: widget.userData.name,
          age: int.tryParse(widget.userData.age) ?? 65,
          gender: widget.userData.gender,
          height: int.tryParse(widget.userData.height) ?? 170,
          weight: int.tryParse(widget.userData.weight) ?? 70,
          youtubeUrl: "텍스트: $inputText",
        );
      }

      Navigator.of(context).pop();
      _showAIFactCheckResult(result);

    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      print('❌ 팩트체킹 오류: $e');
      
      // 더 자세한 오류 메시지 제공
      String errorMessage = '팩트체킹 중 오류가 발생했습니다';
      if (e.toString().contains('네트워크 연결')) {
        errorMessage = '네트워크 연결을 확인해주세요.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = '네트워크 연결을 확인해주세요.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.blue, // 파란색으로 변경
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '다시 시도',
              textColor: Colors.white,
              onPressed: () => _performFactCheck(inputText),
            ),
          ),
        );
      }
    }
  }

  void _showAIFactCheckResult(Map<String, dynamic> aiResult) {
    final credibility = aiResult['overall_credibility'] ?? '보통';
    final factCheckResult = aiResult['fact_check_result'] ?? '분석 결과가 없습니다.';
    
    Color credibilityColor;
    IconData credibilityIcon;
    String credibilityMessage;
    
    switch (credibility) {
      case '높음':
        credibilityColor = Colors.green;
        credibilityIcon = Icons.check_circle;
        credibilityMessage = '신뢰할 수 있는 정보입니다';
        break;
      case '낮음':
        credibilityColor = const Color(0xFF2196F3); // 파란색으로 변경
        credibilityIcon = Icons.warning;
        credibilityMessage = '주의가 필요한 정보입니다';
        break;
      default:
        credibilityColor = const Color(0xFF64B5F6); // 연한 파란색으로 변경
        credibilityIcon = Icons.info;
        credibilityMessage = '추가 확인이 필요한 정보입니다';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fact_check, color: const Color(0xFF2196F3), size: 28), // 파란색으로 변경
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'AI 팩트체크 결과',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: credibilityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: credibilityColor.withOpacity(0.3), width: 2),
              ),
              child: Row(
                children: [
                  Icon(credibilityIcon, color: credibilityColor, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          credibilityMessage,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: credibilityColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '신뢰도: $credibility',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700, // 글씨 두께 더 증가
                            color: credibilityColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.psychology, color: Color(0xFFE57373), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'AI 분석 결과',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        factCheckResult,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700, // 글씨 두께 더 증가
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE57373),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '확인했어요',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MealDataProvider, MedicationProvider>(
      builder: (context, mealProvider, medicationProvider, child) {
        final weekDates = _getWeekDates(medicationProvider.currentWeekStart);
        final today = DateTime.now().toIso8601String().split('T')[0];
        final selectedDayData = medicationProvider.getDayMedications(medicationProvider.selectedDate) ?? 
            DayMedications(medications: [], completed: []);
        final completedCount = selectedDayData.completed.length;
        final totalCount = selectedDayData.medications.length;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: SafeArea(
            child: Column(
              children: [
                // 헤더
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.userData.name}님, 안녕하세요! 👋',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '오늘도 건강한 하루 보내세요',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // 주간 캘린더
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
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
                            children: [
                              // 주간 네비게이션
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    onPressed: () => medicationProvider.previousWeek(),
                                    icon: const Icon(Icons.chevron_left, size: 32),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.grey[100],
                                      padding: const EdgeInsets.all(12),
                                    ),
                                  ),
                                  Text(
                                    '${medicationProvider.currentWeekStart.month}월 ${medicationProvider.currentWeekStart.day}일 ~ ${weekDates[6].month}월 ${weekDates[6].day}일',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => medicationProvider.nextWeek(),
                                    icon: const Icon(Icons.chevron_right, size: 32),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.grey[100],
                                      padding: const EdgeInsets.all(12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // 주간 달력
                              Row(
                                children: weekDates.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final date = entry.value;
                                  final dateKey = date.toIso8601String().split('T')[0];
                                  final isSelected = dateKey == medicationProvider.selectedDate;
                                  final isToday = dateKey == today;
                                  final dayData = medicationProvider.getDayMedications(dateKey);
                                  final progress = dayData != null && dayData.medications.isNotEmpty
                                      ? (dayData.completed.length / dayData.medications.length)
                                      : 0.0;
                                  
                                  // 식단 데이터 가져오기
                                  final meals = mealProvider.getMealsForDate(dateKey);
                                  final hasMeals = meals.isNotEmpty;

                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () => medicationProvider.setSelectedDate(dateKey),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFF2196F3) : (isToday ? const Color(0xFFF3F9FF) : Colors.white), // 파란색으로 변경
                                          border: Border.all(
                                            color: isSelected ? const Color(0xFF2196F3) : (isToday ? const Color(0xFFBBDEFB) : Colors.grey[200]!), // 파란색으로 변경
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              weekDays[index],
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: isSelected ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '${date.day}',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            
                                            // 복약 진행률
                                            Container(
                                              width: double.infinity,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                              child: FractionallySizedBox(
                                                alignment: Alignment.centerLeft,
                                                widthFactor: progress,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: isSelected ? Colors.white : const Color(0xFF2196F3), // 파란색으로 변경
                                                    borderRadius: BorderRadius.circular(2),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            
                                            // 식단 표시
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    color: hasMeals 
                                                        ? (isSelected ? Colors.white : const Color(0xFF64B5F6)) // 연한 파란색으로 변경
                                                        : Colors.grey[300],
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 2),
                                                Icon(
                                                  Icons.restaurant,
                                                  size: 12,
                                                  color: hasMeals 
                                                      ? (isSelected ? Colors.white : const Color(0xFF64B5F6)) // 연한 파란색으로 변경
                                                      : Colors.grey[300],
                                                ),
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

                        const SizedBox(height: 20),

                        // 오늘의 복약 리스트
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
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
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '오늘의 복약',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '$completedCount/$totalCount',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2196F3), // 파란색으로 변경
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              ...selectedDayData.medications.map((medication) {
                                final isCompleted = selectedDayData.completed.contains(medication.id);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isCompleted ? Colors.green[50] : Colors.grey[50],
                                    border: Border.all(
                                      color: isCompleted ? Colors.green[300]! : Colors.grey[200]!,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              medication.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              medication.time,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => medicationProvider.toggleMedicationComplete(medication.id),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isCompleted ? const Color(0xFF4CAF50) : const Color(0xFF2196F3), // 파란색으로 변경
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (isCompleted) ...[
                                              const Icon(Icons.check, size: 16),
                                              const SizedBox(width: 4),
                                              const Text('완료'),
                                            ] else
                                              const Text('복용하기'),
                                          ],
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

                        // 건강 정보 팩트체크 섹션
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2196F3), Color(0xFF64B5F6)], // 파란색 그라데이션으로 변경
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2196F3).withOpacity(0.3), // 파란색으로 변경
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.shield_outlined,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '건강 정보 팩트체크',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '의심스러운 건강 정보를 확인해드려요',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700, // 글씨 두께 더 증가
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.warning_amber, color: Colors.white, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          '이런 정보가 의심스러우시다면?',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '• "이거 먹으면 암이 낫는다더라"\n• "당뇨약 끊고 이것만 드세요"\n• "혈압약 대신 이 영양제로"',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600, // 글씨 두께 더 증가
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () => _showFactCheckDialog(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF2196F3), // 파란색으로 변경
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.fact_check, size: 24),
                                      SizedBox(width: 12),
                                      Text(
                                        '이거 진짜 몸에 좋은지 물어보기',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }










}