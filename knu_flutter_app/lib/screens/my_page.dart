import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_data.dart';
import '../providers/analysis_provider.dart';
import '../services/api_service.dart';
import 'onboarding_page.dart';
import 'doctor_view_page.dart';
import 'settings_page.dart';

class MyPage extends StatefulWidget {
  final UserData userData;

  const MyPage({super.key, required this.userData});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with TickerProviderStateMixin {
  late TabController _tabController;
  String selectedHealthMetric = '체중';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 4개 탭으로 변경
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 샘플 건강 데이터
  final Map<String, List<FlSpot>> healthData = {
    '체중': [
      FlSpot(1, 72.5),
      FlSpot(2, 72.2),
      FlSpot(3, 71.8),
      FlSpot(4, 71.5),
      FlSpot(5, 71.2),
      FlSpot(6, 70.9),
      FlSpot(7, 70.6),
    ],
    '혈압': [
      FlSpot(1, 125),
      FlSpot(2, 123),
      FlSpot(3, 128),
      FlSpot(4, 122),
      FlSpot(5, 120),
      FlSpot(6, 118),
      FlSpot(7, 115),
    ],
    '혈당': [
      FlSpot(1, 95),
      FlSpot(2, 92),
      FlSpot(3, 98),
      FlSpot(4, 90),
      FlSpot(5, 88),
      FlSpot(6, 85),
      FlSpot(7, 87),
    ],
    '콜레스테롤': [
      FlSpot(1, 220),
      FlSpot(2, 215),
      FlSpot(3, 210),
      FlSpot(4, 205),
      FlSpot(5, 200),
      FlSpot(6, 195),
      FlSpot(7, 190),
    ],
  };

  final Map<String, String> healthUnits = {
    '체중': 'kg',
    '혈압': 'mmHg',
    '혈당': 'mg/dL',
    '콜레스테롤': 'mg/dL',
  };

  final Map<String, Color> healthColors = {
    '체중': const Color(0xFF2196F3), // 파란색
    '혈압': const Color(0xFF1976D2), // 진한 파란색
    '혈당': const Color(0xFF03DAC6), // 청록색
    '콜레스테롤': const Color(0xFF00BCD4), // 시안색
  };

  // 샘플 복용 의약품 데이터
  final List<Map<String, dynamic>> currentMedications = [
    {
      'name': '메트포르민',
      'dosage': '500mg',
      'frequency': '1일 2회',
      'timing': '아침, 저녁 식후',
      'duration': '2023.03.15 ~ 지속복용',
      'purpose': '당뇨병 치료',
      'prescribedBy': '○○대학병원 내분비내과',
      'sideEffects': '소화불량 가능',
      'compliance': 95,
    },
    {
      'name': '아스피린',
      'dosage': '100mg',
      'frequency': '1일 1회',
      'timing': '아침 식후',
      'duration': '2023.01.10 ~ 지속복용',
      'purpose': '심혈관질환 예방',
      'prescribedBy': '○○병원 순환기내과',
      'sideEffects': '위장장애 주의',
      'compliance': 98,
    },
    {
      'name': '리피토',
      'dosage': '20mg',
      'frequency': '1일 1회',
      'timing': '저녁 식후',
      'duration': '2023.05.20 ~ 지속복용',
      'purpose': '고지혈증 치료',
      'prescribedBy': '○○의원 가정의학과',
      'sideEffects': '근육통 발생시 중단',
      'compliance': 92,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'MyPage',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF2196F3)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '프로필'),
            Tab(text: '건강 지표'),
            Tab(text: '복용 정보'),
            Tab(text: '건강검진'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildHealthMetricsTab(),
          _buildMedicationInfoTab(),
          _buildHealthCheckupTab(), // 새로운 건강검진 탭 추가
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 프로필 섹션
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
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFFF3F9FF), // 연한 파란색으로 변경
                  child: Text(
                    widget.userData.name.isNotEmpty 
                        ? widget.userData.name[0] 
                        : 'U',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3), // 파란색으로 변경
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.userData.name.isNotEmpty 
                      ? widget.userData.name 
                      : '사용자',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.userData.age.isNotEmpty ? widget.userData.age : '0'}세 • ${widget.userData.gender.isNotEmpty ? widget.userData.gender : '미설정'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (widget.userData.height.isNotEmpty && 
                    widget.userData.weight.isNotEmpty &&
                    widget.userData.height != '170' && 
                    widget.userData.weight != '70')
                  Column(
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '${widget.userData.height}cm • ${widget.userData.weight}kg',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.userData.healthConcerns.map((concern) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F9FF), // 연한 파란색으로 변경
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBDEFB)), // 연한 파란색 테두리로 변경
                    ),
                    child: Text(
                      concern,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF2196F3), // 파란색으로 변경
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 설정 섹션
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
                _buildSettingItem(
                  icon: Icons.person,
                  title: '개인정보 수정',
                  onTap: () {
                    _showUpdateProfileDialog();
                  },
                ),
                _buildSettingItem(
                  icon: Icons.notifications,
                  title: '알림 설정',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('알림 설정 페이지로 이동')),
                    );
                  },
                ),
                _buildSettingItem(
                  icon: Icons.health_and_safety,
                  title: '건강 목표 설정',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('건강 목표 설정 페이지로 이동')),
                    );
                  },
                ),
                _buildSettingItem(
                  icon: Icons.backup,
                  title: '데이터 백업',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('데이터 백업 완료')),
                    );
                  },
                ),
                _buildSettingItem(
                  icon: Icons.help,
                  title: '도움말',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('도움말 페이지로 이동')),
                    );
                  },
                ),
                _buildSettingItem(
                  icon: Icons.logout,
                  title: '로그아웃',
                  onTap: () {
                    _showLogoutDialog();
                  },
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetricsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 건강 지표 차트
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '건강 지표 추이',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                // 지표 선택 버튼들
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: healthData.keys.map((metric) => Container(
                      margin: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(metric),
                        selected: selectedHealthMetric == metric,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              selectedHealthMetric = metric;
                            });
                          }
                        },
                        selectedColor: healthColors[metric]?.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: selectedHealthMetric == metric 
                              ? healthColors[metric] 
                              : Colors.grey[600],
                          fontWeight: selectedHealthMetric == metric 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 차트
                SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[300]!,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 25,
                            interval: 1,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              const style = TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              );
                              Widget text;
                              switch (value.toInt()) {
                                case 1:
                                  text = const Text('1주전', style: style);
                                  break;
                                case 2:
                                  text = const Text('6일전', style: style);
                                  break;
                                case 3:
                                  text = const Text('5일전', style: style);
                                  break;
                                case 4:
                                  text = const Text('4일전', style: style);
                                  break;
                                case 5:
                                  text = const Text('3일전', style: style);
                                  break;
                                case 6:
                                  text = const Text('2일전', style: style);
                                  break;
                                case 7:
                                  text = const Text('어제', style: style);
                                  break;
                                default:
                                  text = const Text('', style: style);
                                  break;
                              }
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: text,
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: _getInterval(selectedHealthMetric),
                            reservedSize: 35,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      minX: 1,
                      maxX: 7,
                      minY: _getMinY(selectedHealthMetric),
                      maxY: _getMaxY(selectedHealthMetric),
                      lineBarsData: [
                        LineChartBarData(
                          spots: healthData[selectedHealthMetric]!,
                          isCurved: true,
                          color: healthColors[selectedHealthMetric]!,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 3,
                                color: healthColors[selectedHealthMetric]!,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: healthColors[selectedHealthMetric]!.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // 현재 값과 변화량
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '현재 $selectedHealthMetric',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${healthData[selectedHealthMetric]!.last.y.toStringAsFixed(1)} ${healthUnits[selectedHealthMetric]}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: healthColors[selectedHealthMetric],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '지난주 대비',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              final data = healthData[selectedHealthMetric]!;
                              final change = data.last.y - data.first.y;
                              final isPositive = change > 0;
                              final isImprovement = _isImprovement(selectedHealthMetric, change);
                              
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(
                                    isImprovement ? Icons.trending_up : Icons.trending_down,
                                    color: isImprovement ? Colors.green : const Color(0xFF2196F3), // 하락은 파란색 유지
                                    size: 14,
                                  ),
                                  const SizedBox(width: 2),
                                  Flexible(
                                    child: Text(
                                      '${isPositive ? '+' : ''}${change.toStringAsFixed(1)} ${healthUnits[selectedHealthMetric]}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isImprovement ? Colors.green : const Color(0xFF2196F3), // 하락은 파란색 유지
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 섹션
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.medical_information, color: const Color(0xFF2196F3), size: 24), // 파란색으로 변경
                    const SizedBox(width: 8),
                    const Text(
                      '병원 제출용 복용 정보',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '의료진에게 제출할 수 있는 상세한 복용 정보입니다',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _openDoctorView();
                    },
                    icon: const Icon(Icons.medical_information, size: 20),
                    label: const Text(
                      '의사용 화면 보기',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3), // 파란색으로 변경
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 환자 정보 섹션
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '환자 정보',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('성명', widget.userData.name.isNotEmpty ? widget.userData.name : '사용자'),
                _buildInfoRow('나이', widget.userData.age.isNotEmpty ? '${widget.userData.age}세' : '미설정'),
                _buildInfoRow('성별', widget.userData.gender.isNotEmpty ? widget.userData.gender : '미설정'),
                if (widget.userData.height.isNotEmpty && widget.userData.height != '170')
                  _buildInfoRow('키', '${widget.userData.height}cm'),
                if (widget.userData.weight.isNotEmpty && widget.userData.weight != '70')
                  _buildInfoRow('몸무게', '${widget.userData.weight}kg'),
                _buildInfoRow('작성일', DateFormat('yyyy년 MM월 dd일').format(DateTime.now())),
                if (widget.userData.healthConcerns.isNotEmpty)
                  _buildInfoRow('주요 건강 관심사', widget.userData.healthConcerns.join(', ')),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 현재 복용 의약품 섹션
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '현재 복용 의약품',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...currentMedications.asMap().entries.map((entry) {
                  final index = entry.key;
                  final medication = entry.value;
                  return Column(
                    children: [
                      _buildMedicationCard(medication, index + 1),
                      if (index < currentMedications.length - 1)
                        const SizedBox(height: 12),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 복용 순응도 통계
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '복용 순응도 (최근 30일)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...currentMedications.map((medication) {
                  final compliance = medication['compliance'] as int;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              medication['name'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '$compliance%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _getComplianceColor(compliance),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: compliance / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getComplianceColor(compliance),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F9FF), // 연한 파란색으로 변경
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: const Color(0xFF2196F3), size: 16), // 파란색으로 변경
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '복용 순응도는 처방된 용법·용량을 정확히 지킨 비율입니다',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF2196F3), // 파란색으로 변경
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 알레르기 및 주의사항
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '알레르기 및 주의사항',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange[600], size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            '알려진 알레르기',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• 페니실린 계열 항생제\n• 아스피린 (고용량 시 위장장애)',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50], // 파란색으로 변경
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!), // 파란색으로 변경
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.medical_services, color: Colors.blue[600], size: 16), // 파란색으로 변경
                          const SizedBox(width: 8),
                          const Text(
                            '복용 시 주의사항',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• 메트포르민: 신장기능 검사 정기 실시\n• 리피토: 근육통 발생 시 즉시 중단\n• 아스피린: 위장보호제와 함께 복용',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 법적 고지
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.gavel, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '법적 고지',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '본 정보는 환자가 직접 입력한 내용을 바탕으로 작성되었으며, 의학적 진단이나 처방을 대체할 수 없습니다. 정확한 의학적 판단은 반드시 의료진과 상담하시기 바랍니다.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(Map<String, dynamic> medication, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3), // 파란색으로 변경
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    index.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  medication['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMedicationDetail('용량', medication['dosage']),
          _buildMedicationDetail('복용 횟수', medication['frequency']),
          _buildMedicationDetail('복용 시간', medication['timing']),
          _buildMedicationDetail('복용 기간', medication['duration']),
          _buildMedicationDetail('처방 목적', medication['purpose']),
          _buildMedicationDetail('처방 기관', medication['prescribedBy']),
          _buildMedicationDetail('부작용 주의', medication['sideEffects']),
        ],
      ),
    );
  }

  Widget _buildMedicationDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getComplianceColor(int compliance) {
    if (compliance >= 95) return Colors.green; // 우수: 초록색
    if (compliance >= 85) return Colors.orange; // 보통: 노란색
    return Colors.red; // 부족: 빨간색
  }

  void _openDoctorView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorViewPage(userData: widget.userData),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: isLast ? null : Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  double _getInterval(String metric) {
    switch (metric) {
      case '체중':
        return 1;
      case '혈압':
        return 10;
      case '혈당':
        return 5;
      case '콜레스테롤':
        return 10;
      default:
        return 1;
    }
  }

  double _getMinY(String metric) {
    final data = healthData[metric]!;
    final minValue = data.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    return minValue - (minValue * 0.1);
  }

  double _getMaxY(String metric) {
    final data = healthData[metric]!;
    final maxValue = data.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    return maxValue + (maxValue * 0.1);
  }

  bool _isImprovement(String metric, double change) {
    switch (metric) {
      case '체중':
        return change < 0; // 체중 감소가 개선
      case '혈압':
      case '혈당':
      case '콜레스테롤':
        return change < 0; // 수치 감소가 개선
      default:
        return change > 0;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('로그아웃되었습니다')),
              );
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  void _showUpdateProfileDialog() {
    final bool hasIncompleteData = widget.userData.height == '170' || 
                                   widget.userData.weight == '70' ||
                                   widget.userData.name.isEmpty ||
                                   widget.userData.age.isEmpty ||
                                   widget.userData.gender.isEmpty;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('개인정보 수정'),
        content: Text(hasIncompleteData 
            ? '일부 개인정보가 누락되었습니다.\n온보딩을 다시 진행하여 정보를 완성하시겠습니까?'
            : '개인정보를 수정하려면 온보딩을 다시 진행해야 합니다.\n계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetUserData();
            },
            child: const Text('온보딩 다시 하기'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const OnboardingPage(),
        ),
        (route) => false,
      );
    }
  }

  // 건강검진 탭 추가
  Widget _buildHealthCheckupTab() {
    return Consumer<AnalysisProvider>(
      builder: (context, analysisProvider, child) {
        final checkupAnalysis = analysisProvider.currentCheckupAnalysis;
        final checkupHistory = analysisProvider.checkupHistory;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 최근 건강검진 결과
              if (checkupAnalysis != null) ...[
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getStatusColor(checkupAnalysis['status'] ?? 'Unknown').withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getStatusIcon(checkupAnalysis['status'] ?? 'Unknown'),
                              color: _getStatusColor(checkupAnalysis['status'] ?? 'Unknown'),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '최근 건강검진 결과',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '등록일: ${DateFormat('yyyy년 MM월 dd일').format(DateTime.now())}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(checkupAnalysis['status'] ?? 'Unknown').withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getStatusColor(checkupAnalysis['status'] ?? 'Unknown'),
                              ),
                            ),
                            child: Text(
                              _getStatusMessage(checkupAnalysis['status'] ?? 'Unknown'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(checkupAnalysis['status'] ?? 'Unknown'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // 간단한 요약
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Text(
                          (checkupAnalysis['content']?.toString().length ?? 0) > 100
                              ? '${checkupAnalysis['content'].toString().substring(0, 100)}...'
                              : checkupAnalysis['content']?.toString() ?? '분석 결과가 없습니다.',
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // 상세 보기 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showDetailedCheckupResult(checkupAnalysis),
                          icon: const Icon(Icons.visibility, size: 20),
                          label: const Text(
                            '상세 결과 보기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3), // 파란색으로 변경
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 건강검진 업로드 섹션
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
                        Icon(Icons.add_a_photo, color: const Color(0xFF2196F3), size: 24), // 파란색으로 변경
                        const SizedBox(width: 8),
                        const Text(
                          '건강검진 결과지 등록',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '건강검진 결과지를 촬영하면 AI가 자동으로 분석해드려요',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _handleHealthCheckupCamera(),
                            icon: const Icon(Icons.camera_alt, size: 20),
                            label: const Text(
                              '카메라로 촬영',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3), // 파란색으로 변경
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _handleHealthCheckupUpload(),
                            icon: const Icon(Icons.photo_library, size: 20),
                            label: const Text(
                              '갤러리에서 선택',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2196F3), // 파란색으로 변경
                              side: const BorderSide(color: Color(0xFF2196F3)), // 파란색으로 변경
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // 건강검진 기록
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
                        Icon(Icons.history, color: const Color(0xFF2196F3), size: 24), // 파란색으로 변경
                        const SizedBox(width: 8),
                        const Text(
                          '건강검진 기록',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (checkupHistory.isEmpty && checkupAnalysis == null) ...[
                      // 검진 기록이 없을 때
                      Container(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.health_and_safety_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '등록된 건강검진 결과가 없습니다.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '홈페이지에서 건강검진 결과지를 촬영하여\n등록해보세요!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // 검진 기록이 있을 때
                      if (checkupAnalysis != null)
                        _buildCheckupHistoryItem(
                          '최근 건강검진',
                          DateTime.now(),
                          checkupAnalysis['status'] ?? 'Unknown',
                          () => _showDetailedCheckupResult(checkupAnalysis),
                        ),
                      
                      // 추가 기록들 (샘플)
                      _buildCheckupHistoryItem(
                        '정기 건강검진',
                        DateTime.now().subtract(const Duration(days: 365)),
                        'Green',
                        () => _showSampleCheckupResult('2023년 정기검진'),
                      ),
                      _buildCheckupHistoryItem(
                        '종합 건강검진',
                        DateTime.now().subtract(const Duration(days: 730)),
                        'Yellow',
                        () => _showSampleCheckupResult('2022년 종합검진'),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 건강검진 안내
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.blue[700], size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          '건강검진 안내',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• 정기 건강검진: 2년마다 1회 (40세 이상)\n• 생애전환기 건강진단: 40세, 66세\n• 암 검진: 위암(40세~), 대장암(50세~), 간암(40세~)\n• 건강검진 결과지를 촬영하면 AI가 자동으로 분석해드려요!',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCheckupHistoryItem(String title, DateTime date, String status, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('yyyy년 MM월 dd일').format(date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusMessage(status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(status),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailedCheckupResult(Map<String, dynamic> checkupResult) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.health_and_safety, color: const Color(0xFF2196F3), size: 28), // 파란색으로 변경
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'AI 건강검진 분석 결과',
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
                  color: _getStatusColor(checkupResult['status'] ?? 'Unknown').withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getStatusColor(checkupResult['status'] ?? 'Unknown').withOpacity(0.3), 
                    width: 2
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(checkupResult['status'] ?? 'Unknown'), 
                      color: _getStatusColor(checkupResult['status'] ?? 'Unknown'), 
                      size: 32
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusMessage(checkupResult['status'] ?? 'Unknown'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(checkupResult['status'] ?? 'Unknown'),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '상태: ${checkupResult['status'] ?? 'Unknown'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: _getStatusColor(checkupResult['status'] ?? 'Unknown'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Container(
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
                        Icon(Icons.psychology, color: const Color(0xFF2196F3), size: 20), // 파란색으로 변경
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
                      checkupResult['content'] ?? '분석 결과를 불러올 수 없습니다.',
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (checkupResult['recommended_nutrient'] != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
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
                          Icon(Icons.recommend, color: Colors.green[600], size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            '추천 영양소',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        checkupResult['recommended_nutrient'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3), // 파란색으로 변경
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
      ),
    );
  }

  void _showSampleCheckupResult(String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety, color: const Color(0xFF2196F3), size: 28), // 파란색으로 변경
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
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
            
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '과거 검진 기록',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '이전 건강검진 결과는 참고용으로 표시됩니다.\n상세한 분석은 최근 검진 결과에서 확인하세요.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3), // 파란색으로 변경
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '확인',
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'green':
      case '정상':
        return Colors.green; // 우수: 초록색
      case 'yellow':
      case '주의':
        return Colors.orange; // 보통: 노란색
      case 'red':
      case '위험':
        return Colors.red; // 부족: 빨간색
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'green':
      case '정상':
        return Icons.check_circle;
      case 'yellow':
      case '주의':
        return Icons.warning;
      case 'red':
      case '위험':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'green':
        return '정상';
      case 'yellow':
        return '주의';
      case 'red':
        return '위험';
      case '정상':
        return '건강 상태 양호';
      case '주의':
        return '주의 필요';
      case '위험':
        return '관리 필요';
      default:
        return '상태 확인 필요';
    }
  }

  // 건강검진 업로드 메서드들
  void _handleHealthCheckupCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      
      if (image != null) {
        // 로딩 다이얼로그 표시
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Expanded(
                  child: Text('AI가 건강검진 결과를 분석하고 있습니다...'),
                ),
              ],
            ),
          ),
        );

        try {
          // 실제 건강검진 데이터로 분석 (샘플 데이터 사용)
          final checkupText = "혈압: 135/85 mmHg, 총콜레스테롤: 200 mg/dL, 혈당: 95 mg/dL, BMI: 23.8, HDL콜레스테롤: 45 mg/dL, LDL콜레스테롤: 130 mg/dL, 중성지방: 150 mg/dL";
          
          print('🏥 건강검진 분석 시작: ${widget.userData.name}');
          
          final analysisResult = await ApiService.analyzeCheckup(
            name: widget.userData.name,
            age: int.tryParse(widget.userData.age) ?? 65,
            gender: widget.userData.gender,
            height: int.tryParse(widget.userData.height) ?? 170,
            weight: int.tryParse(widget.userData.weight) ?? 70,
            checkupText: checkupText,
          );

          // 로딩 다이얼로그 닫기
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }

          // AnalysisProvider에 건강검진 결과 저장
          if (mounted) {
            final analysisProvider = Provider.of<AnalysisProvider>(context, listen: false);
            await analysisProvider.saveCheckupAnalysis(analysisResult, image.path);
            print('✅ 건강검진 결과 저장 완료');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('건강검진 분석이 완료되었습니다! 결과를 확인해보세요.'),
              backgroundColor: Colors.green,
            ),
          );

          _showDetailedCheckupResult(analysisResult);
          
        } catch (apiError) {
          // 로딩 다이얼로그 닫기
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
          
          print('❌ 건강검진 API 오류: $apiError');
          
          final errorResult = {
            'status': 'Error',
            'content': 'API 서버 연결 오류로 분석을 완료하지 못했습니다. 네트워크 연결을 확인하고 다시 시도해주세요.',
            'recommended_nutrient': '서버 연결 후 다시 시도해주세요.'
          };

          // 오류 결과도 저장
          if (mounted) {
            final analysisProvider = Provider.of<AnalysisProvider>(context, listen: false);
            await analysisProvider.saveCheckupAnalysis(errorResult, image.path);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('건강검진 분석 오류: 네트워크 연결을 확인해주세요.'),
              backgroundColor: const Color(0xFF2196F3),
              action: SnackBarAction(
                label: '다시 시도',
                textColor: Colors.white,
                onPressed: () => _handleHealthCheckupCamera(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // 로딩 다이얼로그가 열려있다면 닫기
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      print('❌ 카메라 사용 오류: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('카메라 사용 중 오류가 발생했습니다: $e'),
          backgroundColor: const Color(0xFF2196F3),
        ),
      );
    }
  }

  void _handleHealthCheckupUpload() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        // 로딩 다이얼로그 표시
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Expanded(
                  child: Text('AI가 건강검진 결과를 분석하고 있습니다...'),
                ),
              ],
            ),
          ),
        );

        try {
          // 실제 건강검진 데이터로 분석 (샘플 데이터 사용)
          final checkupText = "혈압: 140/90 mmHg, 총콜레스테롤: 220 mg/dL, 혈당: 110 mg/dL, BMI: 24.5, HDL콜레스테롤: 40 mg/dL, LDL콜레스테롤: 140 mg/dL, 중성지방: 180 mg/dL";
          
          print('🏥 건강검진 분석 시작: ${widget.userData.name}');
          
          final analysisResult = await ApiService.analyzeCheckup(
            name: widget.userData.name,
            age: int.tryParse(widget.userData.age) ?? 65,
            gender: widget.userData.gender,
            height: int.tryParse(widget.userData.height) ?? 170,
            weight: int.tryParse(widget.userData.weight) ?? 70,
            checkupText: checkupText,
          );

          // 로딩 다이얼로그 닫기
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }

          // AnalysisProvider에 건강검진 결과 저장
          if (mounted) {
            final analysisProvider = Provider.of<AnalysisProvider>(context, listen: false);
            await analysisProvider.saveCheckupAnalysis(analysisResult, image.path);
            print('✅ 건강검진 결과 저장 완료');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('건강검진 분석이 완료되었습니다! 결과를 확인해보세요.'),
              backgroundColor: Colors.green,
            ),
          );

          _showDetailedCheckupResult(analysisResult);
          
        } catch (apiError) {
          // 로딩 다이얼로그 닫기
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
          
          print('❌ 건강검진 API 오류: $apiError');
          
          final errorResult = {
            'status': 'Error',
            'content': 'API 서버 연결 오류로 분석을 완료하지 못했습니다. 네트워크 연결을 확인하고 다시 시도해주세요.',
            'recommended_nutrient': '서버 연결 후 다시 시도해주세요.'
          };

          // 오류 결과도 저장
          if (mounted) {
            final analysisProvider = Provider.of<AnalysisProvider>(context, listen: false);
            await analysisProvider.saveCheckupAnalysis(errorResult, image.path);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('건강검진 분석 오류: 네트워크 연결을 확인해주세요.'),
              backgroundColor: const Color(0xFF2196F3),
              action: SnackBarAction(
                label: '다시 시도',
                textColor: Colors.white,
                onPressed: () => _handleHealthCheckupUpload(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // 로딩 다이얼로그가 열려있다면 닫기
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      print('❌ 갤러리 사용 오류: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('갤러리 사용 중 오류가 발생했습니다: $e'),
          backgroundColor: const Color(0xFF2196F3),
        ),
      );
    }
  }
}