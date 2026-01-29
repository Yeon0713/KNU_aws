import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/user_data.dart';
import '../providers/analysis_provider.dart';

class CalendarPage extends StatefulWidget {
  final UserData userData;

  const CalendarPage({super.key, required this.userData});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 복약 준수율 데이터 (샘플)
  final Map<String, double> medicationCompliance = {
    '2026-01-15': 1.0,  // 100% - 초록
    '2026-01-16': 0.75, // 75% - 노랑
    '2026-01-17': 1.0,
    '2026-01-18': 0.5,  // 50% - 빨강
    '2026-01-19': 1.0,
    '2026-01-20': 0.8,  // 80% - 노랑
    '2026-01-21': 1.0,
    '2026-01-22': 0.25, // 25% - 빨강
    '2026-01-23': 1.0,
    '2026-01-24': 0.9,  // 90% - 노랑
    '2026-01-25': 1.0,
    '2026-01-26': 0.6,  // 60% - 노랑
    '2026-01-27': 1.0,
  };

  Color _getComplianceColor(double compliance) {
    if (compliance >= 0.9) return Colors.green; // 우수: 초록색
    if (compliance >= 0.7) return Colors.orange; // 보통: 노란색
    return Colors.red; // 부족: 빨간색
  }

  String _getComplianceText(double compliance) {
    if (compliance >= 0.9) return '우수';
    if (compliance >= 0.7) return '보통';
    return '부족';
  }

  List<Map<String, dynamic>> _getMonthlyStats() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    
    int totalDays = 0;
    int excellentDays = 0;
    int goodDays = 0;
    int poorDays = 0;
    double totalCompliance = 0;

    for (int i = 1; i <= lastDay.day; i++) {
      final date = DateTime(now.year, now.month, i);
      if (date.isAfter(now)) break;
      
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final compliance = medicationCompliance[dateKey] ?? 0.0;
      
      totalDays++;
      totalCompliance += compliance;
      
      if (compliance >= 0.9) {
        excellentDays++;
      } else if (compliance >= 0.7) {
        goodDays++;
      } else {
        poorDays++;
      }
    }

    final averageCompliance = totalDays > 0 ? totalCompliance / totalDays : 0.0;

    return [
      {
        'title': '평균 복약률',
        'value': '${(averageCompliance * 100).toInt()}%',
        'color': _getComplianceColor(averageCompliance),
        'icon': Icons.medication,
      },
      {
        'title': '우수한 날',
        'value': '$excellentDays일',
        'color': Colors.green,
        'icon': Icons.check_circle,
      },
      {
        'title': '보통인 날',
        'value': '$goodDays일',
        'color': Colors.orange,
        'icon': Icons.warning,
      },
      {
        'title': '부족한 날',
        'value': '$poorDays일',
        'color': Colors.red, // 빨간색으로 되돌림
        'icon': Icons.error,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final monthlyStats = _getMonthlyStats();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '월별 복약 현황',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 월별 통계
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
                  Text(
                    '${DateFormat('yyyy년 M월').format(_focusedDay)} 통계',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200, // 고정 높이 설정
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: monthlyStats.length,
                      itemBuilder: (context, index) {
                        final stat = monthlyStats[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: stat['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: stat['color'].withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                stat['icon'],
                                color: stat['color'],
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                stat['value'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: stat['color'],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                stat['title'],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 캘린더
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
                  TableCalendar<String>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      weekendTextStyle: const TextStyle(color: Colors.red),
                      holidayTextStyle: const TextStyle(color: Colors.red),
                      selectedDecoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                      selectedTextStyle: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue,
                          width: 1,
                        ),
                      ),
                      todayTextStyle: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                      markerDecoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      selectedBuilder: (context, day, focusedDay) {
                        final dateKey = DateFormat('yyyy-MM-dd').format(day);
                        final compliance = medicationCompliance[dateKey];
                        
                        if (compliance != null) {
                          // 복약 데이터가 있는 날짜가 선택된 경우
                          return Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _getComplianceColor(compliance).withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _getComplianceColor(compliance),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: _getComplianceColor(compliance),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }
                        
                        // 복약 데이터가 없는 날짜가 선택된 경우 (기본 스타일 사용)
                        return Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey[400]!,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                      defaultBuilder: (context, day, focusedDay) {
                        final dateKey = DateFormat('yyyy-MM-dd').format(day);
                        final compliance = medicationCompliance[dateKey];
                        
                        if (compliance != null) {
                          return Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _getComplianceColor(compliance),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                      todayBuilder: (context, day, focusedDay) {
                        final dateKey = DateFormat('yyyy-MM-dd').format(day);
                        final compliance = medicationCompliance[dateKey];
                        
                        return Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: compliance != null 
                                ? _getComplianceColor(compliance)
                                : Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                color: compliance != null ? Colors.white : Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 범례
                  Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    children: [
                      _buildLegendItem(Colors.green, '우수 (90%+)'),
                      _buildLegendItem(Colors.orange, '보통 (70-89%)'),
                      _buildLegendItem(Colors.red, '부족 (70% 미만)'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 선택된 날짜 정보
            if (_selectedDay != null)
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('yyyy년 M월 d일 (E)').format(_selectedDay!),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Builder(
                      builder: (context) {
                        final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDay!);
                        final compliance = medicationCompliance[dateKey];
                        
                        if (compliance == null) {
                          return const Text(
                            '이 날짜에는 복약 기록이 없습니다.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          );
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: _getComplianceColor(compliance),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '복약률: ${(compliance * 100).toInt()}% (${_getComplianceText(compliance)})',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: compliance,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getComplianceColor(compliance),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              compliance >= 0.9
                                  ? '훌륭합니다! 꾸준히 복약하고 계시네요.'
                                  : compliance >= 0.7
                                      ? '좋습니다. 조금 더 꾸준히 복약해보세요.'
                                      : '복약을 놓친 날이 있네요. 알림을 설정해보세요.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20), // 하단 여백 추가
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}